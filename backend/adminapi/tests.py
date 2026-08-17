import io

import pytest
from PIL import Image
from rest_framework.test import APIClient

from invitations.models import Invitation
from listings.models import Listing
from reports.models import Report
from users.models import User

pytestmark = pytest.mark.django_db


def make_admin(phone="+237600000900"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ADMIN)


def make_annonceur(phone="+237600000901"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ANNONCEUR)


def make_locataire(phone="+237600000902"):
    return User.objects.create_user(phone_number=phone, role=User.Role.LOCATAIRE)


def make_listing(owner=None, **overrides):
    defaults = dict(
        title="Studio meublé",
        neighborhood="Bastos",
        property_type=Listing.PropertyType.STUDIO,
        rent_amount=75000,
        whatsapp_number="+237600001000",
        status=Listing.Status.EN_ATTENTE,
    )
    defaults.update(overrides)
    return Listing.objects.create(owner=owner, **defaults)


class TestAdminAccess:
    def test_non_admin_cannot_access_dashboard(self):
        client = APIClient()
        client.force_authenticate(make_annonceur())
        response = client.get("/api/admin/dashboard/")
        assert response.status_code == 403

    def test_unauthenticated_cannot_access_dashboard(self):
        response = APIClient().get("/api/admin/dashboard/")
        assert response.status_code == 401

    def test_admin_can_access_dashboard(self):
        client = APIClient()
        client.force_authenticate(make_admin())
        response = client.get("/api/admin/dashboard/")
        assert response.status_code == 200
        assert "listings_pending_count" in response.data
        assert len(response.data["listings_published_by_day"]) == 14
        assert len(response.data["signups_by_day"]) == 14


class TestAdminListingModeration:
    def test_admin_sees_all_listings_regardless_of_owner(self):
        make_listing(owner=make_annonceur("+237600000910"), title="Bien A")
        make_listing(owner=make_annonceur("+237600000911"), title="Bien B")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000912"))

        response = client.get("/api/admin/listings/")

        titles = {item["title"] for item in response.data["results"]}
        assert titles == {"Bien A", "Bien B"}

    def test_admin_can_approve_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000913"))
        client = APIClient()
        client.force_authenticate(make_admin("+237600000914"))

        response = client.post(f"/api/admin/listings/{listing.id}/approve/")

        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == Listing.Status.PUBLIEE

    def test_admin_can_reject_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000915"))
        client = APIClient()
        client.force_authenticate(make_admin("+237600000916"))

        response = client.post(f"/api/admin/listings/{listing.id}/reject/")

        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == Listing.Status.REJETEE

    def test_annonceur_cannot_approve_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000917"))
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000918"))

        response = client.post(f"/api/admin/listings/{listing.id}/approve/")

        assert response.status_code == 403

    def test_admin_can_create_amorce_listing(self):
        client = APIClient()
        client.force_authenticate(make_admin("+237600000919"))

        response = client.post("/api/admin/listings/", {
            "title": "Villa amorçage", "neighborhood": "Odza",
            "property_type": Listing.PropertyType.VILLA, "rent_amount": 350000,
            "whatsapp_number": "+237600001100", "seed_contact_name": "D. Fouda",
            "seed_contact_phone": "+237600001101",
        })

        assert response.status_code == 201
        assert response.data["source"] == Listing.Source.AMORCE
        assert response.data["status"] == Listing.Status.PUBLIEE
        assert response.data["owner"] is None

    def test_admin_can_upload_media_to_created_listing(self):
        client = APIClient()
        client.force_authenticate(make_admin("+237600000923"))
        listing = client.post("/api/admin/listings/", {
            "title": "Studio amorçage", "neighborhood": "Nlongkak",
            "property_type": Listing.PropertyType.STUDIO, "rent_amount": 60000,
            "whatsapp_number": "+237600001102",
        }).data

        buffer = io.BytesIO()
        Image.new("RGB", (10, 10), color="green").save(buffer, format="JPEG")
        buffer.seek(0)
        buffer.name = "photo.jpg"

        response = client.post(
            f"/api/admin/listings/{listing['id']}/upload_media/",
            {"media_type": "photo", "file": buffer, "order": 0},
            format="multipart",
        )

        assert response.status_code == 201
        assert Listing.objects.get(id=listing["id"]).media.count() == 1


class TestAdminUsers:
    def test_admin_can_list_users_filtered_by_role(self):
        make_annonceur("+237600000920")
        make_locataire("+237600000921")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000922"))

        response = client.get("/api/admin/users/", {"role": "annonceur"})

        assert all(item["role"] == "annonceur" for item in response.data["results"])
        assert response.data["count"] == 1

    def test_admin_can_search_users(self):
        make_annonceur("+237600000923")
        User.objects.filter(phone_number="+237600000923").update(full_name="Ateba Marie")
        make_locataire("+237600000924")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000925"))

        response = client.get("/api/admin/users/", {"search": "Ateba"})

        assert response.data["count"] == 1
        assert response.data["results"][0]["full_name"] == "Ateba Marie"


class TestAdminInvitations:
    def test_admin_can_send_invitation_for_amorce_listing(self):
        listing = make_listing(
            owner=None, source=Listing.Source.AMORCE, status=Listing.Status.PUBLIEE,
            seed_contact_name="M. Ateba", seed_contact_phone="+237600001200",
        )
        client = APIClient()
        client.force_authenticate(make_admin("+237600000930"))

        response = client.post("/api/admin/invitations/", {
            "phone_number": listing.seed_contact_phone, "listing_id": listing.id,
        })

        assert response.status_code == 201
        assert Invitation.objects.filter(phone_number="+237600001200", listing=listing).exists()

    def test_admin_can_list_invitations(self):
        client = APIClient()
        client.force_authenticate(make_admin("+237600000931"))
        client.post("/api/admin/invitations/", {"phone_number": "+237600001300"})

        response = client.get("/api/admin/invitations/")

        assert response.data["count"] == 1


class TestAdminReports:
    def test_admin_can_list_and_resolve_reports(self):
        listing = make_listing(owner=make_annonceur("+237600000940"))
        reporter = make_locataire("+237600000941")
        report = Report.objects.create(
            listing=listing, reporter=reporter, reason=Report.Reason.FAUSSE_ANNONCE,
        )
        client = APIClient()
        client.force_authenticate(make_admin("+237600000942"))

        list_response = client.get("/api/admin/reports/")
        assert list_response.data["count"] == 1

        resolve_response = client.post(f"/api/admin/reports/{report.id}/resolve/", {"status": "traite"})
        assert resolve_response.status_code == 200
        report.refresh_from_db()
        assert report.status == Report.Status.TRAITE
