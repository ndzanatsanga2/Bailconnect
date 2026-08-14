import pytest
from rest_framework.test import APIClient

from listings.models import Listing
from reports.models import Report
from users.models import User

pytestmark = pytest.mark.django_db


def make_locataire(phone="+237600000950"):
    return User.objects.create_user(phone_number=phone, role=User.Role.LOCATAIRE)


def make_annonceur(phone="+237600000951"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ANNONCEUR)


def make_admin(phone="+237600000952"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ADMIN)


def make_listing(owner=None, **overrides):
    defaults = dict(
        title="Studio meublé",
        neighborhood="Bastos",
        property_type=Listing.PropertyType.STUDIO,
        rent_amount=75000,
        whatsapp_number="+237600001000",
        status=Listing.Status.PUBLIEE,
    )
    defaults.update(overrides)
    return Listing.objects.create(owner=owner, **defaults)


class TestReportCreate:
    def test_authenticated_user_can_report_a_listing(self):
        listing = make_listing(owner=make_annonceur())
        client = APIClient()
        client.force_authenticate(make_locataire())

        response = client.post("/api/reports/", {
            "listing": listing.id,
            "reason": Report.Reason.FAUSSE_ANNONCE,
            "description": "Le bien n'existe pas à cette adresse.",
        })

        assert response.status_code == 201
        assert Report.objects.filter(listing=listing, reason=Report.Reason.FAUSSE_ANNONCE).exists()

    def test_invalid_reason_returns_400(self):
        listing = make_listing(owner=make_annonceur("+237600000960"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000961"))

        response = client.post("/api/reports/", {
            "listing": listing.id,
            "reason": "raison_inconnue",
        })

        assert response.status_code == 400
        assert "reason" in response.data

    def test_unauthenticated_user_cannot_report(self):
        listing = make_listing(owner=make_annonceur("+237600000962"))

        response = APIClient().post("/api/reports/", {
            "listing": listing.id,
            "reason": Report.Reason.AUTRE,
        })

        assert response.status_code == 401

    def test_duplicate_open_report_from_same_user_is_rejected(self):
        listing = make_listing(owner=make_annonceur("+237600000963"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000964"))
        client.post("/api/reports/", {"listing": listing.id, "reason": Report.Reason.DEJA_LOUE})

        response = client.post("/api/reports/", {"listing": listing.id, "reason": Report.Reason.AUTRE})

        assert response.status_code == 400
        assert Report.objects.filter(listing=listing).count() == 1

    def test_created_report_is_visible_in_admin_backoffice(self):
        listing = make_listing(owner=make_annonceur("+237600000965"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000966"))
        client.post("/api/reports/", {
            "listing": listing.id, "reason": Report.Reason.CONTENU_INAPPROPRIE,
        })

        admin_client = APIClient()
        admin_client.force_authenticate(make_admin())
        response = admin_client.get("/api/admin/reports/")

        assert response.status_code == 200
        assert response.data["count"] == 1
        assert response.data["results"][0]["reason"] == Report.Reason.CONTENU_INAPPROPRIE
