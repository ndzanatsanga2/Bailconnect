"""Script de recette E2E — jalon J5.

Parcours complet couvrant J1→J4 et l'exigence transversale, à travers les
endpoints publics de l'API (comme un client réel) : inscription (téléphone ET
email) → publication → validation admin → fil public (WhatsApp jamais
exposé) → contact (WhatsApp révélé) → amorçage complet (création → invitation
→ acceptation → rattachement avec capacité annonceur) → signalement d'une
annonce.

Seule la récupération du code OTP passe par le service interne : l'API ne
renvoie jamais le code (transmis uniquement par SMS/email), donc un test
« boîte noire » pur ne peut pas l'obtenir autrement.
"""

import pytest
from rest_framework.test import APIClient

from invitations.models import Invitation
from leads.models import Lead
from listings.models import Listing
from reports.models import Report
from users.models import User
from users.services.otp import generate_and_send_otp

pytestmark = pytest.mark.django_db


def _login_with_otp(client, identifier, *, role=None, full_name=""):
    _, code = generate_and_send_otp(identifier)
    payload = {"code": code, "full_name": full_name}
    payload.update({"email": identifier} if "@" in identifier else {"phone_number": identifier})
    if role:
        payload["role"] = role
    response = client.post("/api/auth/otp/verify/", payload)
    assert response.status_code == 200, response.data
    client.credentials(HTTP_AUTHORIZATION=f"Token {response.data['token']}")
    return response.data["user"]


def test_parcours_complet_j1_a_j4():
    admin_client = APIClient()
    admin = User.objects.create_user(phone_number="+237600009000", role=User.Role.ADMIN)
    admin_client.force_authenticate(admin)

    # 1. Inscription — téléphone, en tant qu'annonceur -----------------------
    annonceur_client = APIClient()
    annonceur = _login_with_otp(annonceur_client, "+237600009001", role="annonceur", full_name="Mme Ekotto")
    assert annonceur["role"] == "annonceur"
    assert annonceur["is_annonceur"] is True

    # 1bis. Inscription — email, en tant que locataire ------------------------
    locataire_client = APIClient()
    locataire = _login_with_otp(locataire_client, "locataire.j5@example.com", full_name="M. Biya")
    assert locataire["role"] == "locataire"
    assert locataire["email"] == "locataire.j5@example.com"

    # 2. Publication d'une annonce par l'annonceur ----------------------------
    publish_response = annonceur_client.post("/api/listings/", {
        "title": "Studio meublé Bastos", "neighborhood": "Bastos",
        "property_type": Listing.PropertyType.STUDIO, "rent_amount": 90000,
        "whatsapp_number": "+237600009002",
    })
    assert publish_response.status_code == 201, publish_response.data
    listing_id = publish_response.data["id"]
    assert publish_response.data["status"] == Listing.Status.EN_ATTENTE

    # 3. Validation admin ------------------------------------------------------
    approve_response = admin_client.post(f"/api/admin/listings/{listing_id}/approve/")
    assert approve_response.status_code == 200
    assert approve_response.data["status"] == Listing.Status.PUBLIEE

    # 4. Fil public — WhatsApp jamais exposé ------------------------------------
    feed_response = APIClient().get("/api/feed/")
    assert feed_response.status_code == 200
    fed_listing = next(item for item in feed_response.data if item["id"] == listing_id)
    assert "whatsapp_number" not in fed_listing

    # 5. Contact — révèle le WhatsApp ---------------------------------------------
    contact_response = locataire_client.post("/api/leads/", {"listing_id": listing_id})
    assert contact_response.status_code == 200
    assert contact_response.data["whatsapp_number"] == "+237600009002"
    assert contact_response.data["pending_invitation"] is False
    assert Lead.objects.filter(listing_id=listing_id, tenant__email="locataire.j5@example.com").exists()

    # 6. Amorçage — annonce publiée par l'admin pour un annonceur non inscrit -----
    amorce_response = admin_client.post("/api/admin/listings/", {
        "title": "Villa Odza (amorçage)", "neighborhood": "Odza",
        "property_type": Listing.PropertyType.VILLA, "rent_amount": 250000,
        "whatsapp_number": "+237600009003",
        "seed_contact_name": "M. Ateba", "seed_contact_phone": "+237600009004",
    })
    assert amorce_response.status_code == 201
    amorce_listing_id = amorce_response.data["id"]
    assert amorce_response.data["owner"] is None

    # 6bis. Un locataire contacte l'annonce d'amorçage → invitation envoyée -------
    contact_amorce_response = locataire_client.post("/api/leads/", {"listing_id": amorce_listing_id})
    assert contact_amorce_response.status_code == 200
    assert contact_amorce_response.data["pending_invitation"] is True
    invitation = Invitation.objects.get(listing_id=amorce_listing_id, phone_number="+237600009004")

    # 6ter. Le contact d'amorçage — déjà locataire Bailconnect — accepte l'invitation
    seed_client = APIClient()
    seed_user = _login_with_otp(seed_client, "+237600009004", full_name="M. Ateba")
    assert seed_user["role"] == "locataire"
    assert seed_user["is_annonceur"] is False

    accept_response = APIClient().post(f"/api/invitations/{invitation.token}/accept/", {"full_name": "M. Ateba"})
    assert accept_response.status_code == 200
    assert accept_response.data["user"]["role"] == "locataire"
    assert accept_response.data["user"]["is_annonceur"] is True

    # 6quater. Le compte, désormais locataire + annonceur, gère le bien rattaché --
    manage_response = seed_client.patch(f"/api/listings/{amorce_listing_id}/", {"title": "Villa Odza rénovée"})
    assert manage_response.status_code == 200, manage_response.data
    assert manage_response.data["title"] == "Villa Odza rénovée"

    # 7. Signalement d'une annonce -------------------------------------------------
    report_response = locataire_client.post("/api/reports/", {
        "listing": listing_id, "reason": Report.Reason.FAUSSE_ANNONCE,
        "description": "Contrôle recette J5.",
    })
    assert report_response.status_code == 201
    admin_reports_response = admin_client.get("/api/admin/reports/")
    assert any(r["listing"] == listing_id for r in admin_reports_response.data)
