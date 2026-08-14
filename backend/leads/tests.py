import pytest
from rest_framework.test import APIClient

from invitations.models import Invitation
from leads.models import Lead
from listings.models import Listing
from users.models import User

pytestmark = pytest.mark.django_db


def make_annonceur(phone="+237600000400"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ANNONCEUR)


def make_locataire(phone="+237600000401"):
    return User.objects.create_user(phone_number=phone, role=User.Role.LOCATAIRE)


def make_published_listing(owner=None, **overrides):
    defaults = dict(
        title="Studio meublé moderne",
        neighborhood="Bastos",
        property_type=Listing.PropertyType.STUDIO,
        rent_amount=75000,
        whatsapp_number="+237600000500",
        status=Listing.Status.PUBLIEE,
    )
    defaults.update(overrides)
    return Listing.objects.create(owner=owner, **defaults)


class TestLeadCreation:
    def test_contacting_claimed_listing_creates_lead_and_reveals_whatsapp(self):
        listing = make_published_listing(owner=make_annonceur())
        client = APIClient()
        client.force_authenticate(make_locataire())

        response = client.post("/api/leads/", {"listing_id": listing.id})

        assert response.status_code == 200
        assert response.data["whatsapp_number"] == listing.whatsapp_number
        assert response.data["pending_invitation"] is False
        assert Lead.objects.filter(listing=listing).exists()

    def test_contacting_unclaimed_amorce_listing_triggers_invitation_without_exposing_number(self):
        listing = make_published_listing(
            owner=None,
            source=Listing.Source.AMORCE,
            seed_contact_name="M. Ateba",
            seed_contact_phone="+237600000600",
        )
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000402"))

        response = client.post("/api/leads/", {"listing_id": listing.id})

        assert response.status_code == 200
        assert response.data["whatsapp_number"] is None
        assert response.data["pending_invitation"] is True
        assert Invitation.objects.filter(phone_number="+237600000600", listing=listing).exists()

    def test_unauthenticated_cannot_contact(self):
        listing = make_published_listing(owner=make_annonceur("+237600000403"))
        response = APIClient().post("/api/leads/", {"listing_id": listing.id})
        assert response.status_code == 401

    def test_cannot_contact_unpublished_listing(self):
        listing = make_published_listing(owner=make_annonceur("+237600000404"), status=Listing.Status.EN_ATTENTE)
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000405"))

        response = client.post("/api/leads/", {"listing_id": listing.id})

        assert response.status_code == 404


class TestReceivedLeads:
    def test_annonceur_sees_only_leads_for_own_listings(self):
        owner = make_annonceur("+237600000410")
        other_owner = make_annonceur("+237600000411")
        listing = make_published_listing(owner=owner, title="Bien A")
        other_listing = make_published_listing(owner=other_owner, title="Bien B")
        tenant = make_locataire("+237600000412")
        Lead.objects.create(listing=listing, tenant=tenant)
        Lead.objects.create(listing=other_listing, tenant=tenant)

        client = APIClient()
        client.force_authenticate(owner)
        response = client.get("/api/leads/received/")

        assert response.status_code == 200
        titles = {item["listing_title"] for item in response.data}
        assert titles == {"Bien A"}

    def test_non_annonceur_cannot_list_received_leads(self):
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000413"))
        response = client.get("/api/leads/received/")
        assert response.status_code == 403

    def test_annonceur_can_mark_lead_read(self):
        owner = make_annonceur("+237600000414")
        listing = make_published_listing(owner=owner)
        lead = Lead.objects.create(listing=listing, tenant=make_locataire("+237600000415"))

        client = APIClient()
        client.force_authenticate(owner)
        response = client.post(f"/api/leads/received/{lead.id}/mark_read/")

        assert response.status_code == 200
        assert response.data["is_read"] is True
        lead.refresh_from_db()
        assert lead.is_read is True
