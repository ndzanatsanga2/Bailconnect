import io
import os

import pytest
from PIL import Image
from rest_framework.test import APIClient

from invitations.models import Invitation
from listings.models import Listing, ListingMedia
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

    def test_admin_can_archive_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000916b"), status=Listing.Status.PUBLIEE)
        client = APIClient()
        client.force_authenticate(make_admin("+237600000916c"))

        response = client.post(f"/api/admin/listings/{listing.id}/archive/")

        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == Listing.Status.ARCHIVEE

    def test_annonceur_cannot_archive_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000916d"))
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000916e"))

        response = client.post(f"/api/admin/listings/{listing.id}/archive/")

        assert response.status_code == 403

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

    def test_admin_can_upload_video_media(self):
        client = APIClient()
        client.force_authenticate(make_admin("+237600000924"))
        listing = client.post("/api/admin/listings/", {
            "title": "Chambre amorçage", "neighborhood": "Essos",
            "property_type": Listing.PropertyType.CHAMBRE, "rent_amount": 30000,
            "whatsapp_number": "+237600001103",
        }).data

        video = io.BytesIO(b"fake-mp4-bytes")
        video.name = "visite.mp4"

        response = client.post(
            f"/api/admin/listings/{listing['id']}/upload_media/",
            {"media_type": "video", "file": video, "order": 0},
            format="multipart",
        )

        assert response.status_code == 201
        assert response.data["media_type"] == "video"
        assert response.data["file"].startswith("http://testserver/")


class TestAdminListingDeletion:
    def test_admin_can_delete_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000950"))
        client = APIClient()
        client.force_authenticate(make_admin("+237600000951"))

        response = client.delete(f"/api/admin/listings/{listing.id}/")

        assert response.status_code == 204
        assert not Listing.objects.filter(id=listing.id).exists()

    def test_deleting_listing_removes_media_files_from_storage(self):
        client = APIClient()
        client.force_authenticate(make_admin("+237600000952"))
        listing = client.post("/api/admin/listings/", {
            "title": "Studio à supprimer", "neighborhood": "Mvan",
            "property_type": Listing.PropertyType.STUDIO, "rent_amount": 55000,
            "whatsapp_number": "+237600001104",
        }).data

        buffer = io.BytesIO()
        Image.new("RGB", (10, 10), color="blue").save(buffer, format="JPEG")
        buffer.seek(0)
        buffer.name = "photo.jpg"
        upload_response = client.post(
            f"/api/admin/listings/{listing['id']}/upload_media/",
            {"media_type": "photo", "file": buffer, "order": 0},
            format="multipart",
        )
        media_path = ListingMedia.objects.get(id=upload_response.data["id"]).file.path
        assert os.path.exists(media_path)

        response = client.delete(f"/api/admin/listings/{listing['id']}/")

        assert response.status_code == 204
        assert not os.path.exists(media_path)
        assert not ListingMedia.objects.filter(listing_id=listing["id"]).exists()

    def test_non_admin_cannot_delete_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000953"))
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000954"))

        response = client.delete(f"/api/admin/listings/{listing.id}/")

        assert response.status_code == 403
        assert Listing.objects.filter(id=listing.id).exists()

    def test_unauthenticated_cannot_delete_listing(self):
        listing = make_listing(owner=make_annonceur("+237600000955"))
        client = APIClient()

        response = client.delete(f"/api/admin/listings/{listing.id}/")

        assert response.status_code == 401
        assert Listing.objects.filter(id=listing.id).exists()


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

    def test_admin_can_update_user_profile_fields(self):
        target = make_locataire("+237600000930")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000931"))

        response = client.patch(f"/api/admin/users/{target.id}/", {"full_name": "Nouveau Nom", "city": "Bastos"})

        assert response.status_code == 200
        target.refresh_from_db()
        assert target.full_name == "Nouveau Nom"
        assert target.city == "Bastos"

    def test_admin_cannot_change_role_via_update(self):
        target = make_locataire("+237600000932")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000933"))

        response = client.patch(f"/api/admin/users/{target.id}/", {"role": "admin"})

        assert response.status_code == 200
        target.refresh_from_db()
        assert target.role == User.Role.LOCATAIRE

    def test_non_admin_cannot_update_user(self):
        target = make_locataire("+237600000934")
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000935"))

        response = client.patch(f"/api/admin/users/{target.id}/", {"full_name": "Intrus"})

        assert response.status_code == 403


class TestAdminUserSuspension:
    def test_admin_can_suspend_user(self):
        target = make_locataire("+237600000940")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000941"))

        response = client.post(f"/api/admin/users/{target.id}/suspend/")

        assert response.status_code == 200
        target.refresh_from_db()
        assert target.is_active is False

    def test_suspended_user_cannot_login(self):
        target = User.objects.create_user(
            phone_number="+237600000942", email="suspended@example.com", role=User.Role.LOCATAIRE, password="Correcth0rse9",
        )
        client = APIClient()
        client.force_authenticate(make_admin("+237600000943"))
        client.post(f"/api/admin/users/{target.id}/suspend/")

        response = APIClient().post("/api/auth/login/", {"email": "suspended@example.com", "password": "Correcth0rse9"})

        assert response.status_code == 403

    def test_admin_can_reactivate_suspended_user(self):
        target = User.objects.create_user(
            phone_number="+237600000944", email="reactivated@example.com", role=User.Role.LOCATAIRE, password="Correcth0rse9",
        )
        client = APIClient()
        client.force_authenticate(make_admin("+237600000945"))
        client.post(f"/api/admin/users/{target.id}/suspend/")

        response = client.post(f"/api/admin/users/{target.id}/reactivate/")

        assert response.status_code == 200
        target.refresh_from_db()
        assert target.is_active is True

        login_response = APIClient().post("/api/auth/login/", {"email": "reactivated@example.com", "password": "Correcth0rse9"})
        assert login_response.status_code == 200

    def test_admin_cannot_suspend_own_account(self):
        admin = make_admin("+237600000946")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(f"/api/admin/users/{admin.id}/suspend/")

        assert response.status_code == 400
        admin.refresh_from_db()
        assert admin.is_active is True

    def test_non_admin_cannot_suspend_user(self):
        target = make_locataire("+237600000947")
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000948"))

        response = client.post(f"/api/admin/users/{target.id}/suspend/")

        assert response.status_code == 403


class TestAdminUserArchive:
    def test_admin_can_archive_user(self):
        target = User.objects.create_user(
            phone_number="+237600000960", email="archived@example.com", role=User.Role.LOCATAIRE, password="Correcth0rse9",
        )
        client = APIClient()
        client.force_authenticate(make_admin("+237600000961"))

        response = client.post(f"/api/admin/users/{target.id}/archive/")

        assert response.status_code == 200
        target.refresh_from_db()
        assert target.is_archived is True
        assert target.is_active is False

        login_response = APIClient().post("/api/auth/login/", {"email": "archived@example.com", "password": "Correcth0rse9"})
        assert login_response.status_code == 403

    def test_admin_cannot_archive_own_account(self):
        admin = make_admin("+237600000962")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.post(f"/api/admin/users/{admin.id}/archive/")

        assert response.status_code == 400

    def test_non_admin_cannot_archive_user(self):
        target = make_locataire("+237600000963")
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000964"))

        response = client.post(f"/api/admin/users/{target.id}/archive/")

        assert response.status_code == 403


class TestAdminUserDeletion:
    def test_admin_can_delete_user(self):
        target = make_locataire("+237600000970")
        client = APIClient()
        client.force_authenticate(make_admin("+237600000971"))

        response = client.delete(f"/api/admin/users/{target.id}/")

        assert response.status_code == 204
        assert not User.objects.filter(id=target.id).exists()

    def test_deleting_user_cascades_and_cleans_up_listing_media(self):
        owner = make_annonceur("+237600000972")
        listing = make_listing(owner=owner)
        client = APIClient()
        client.force_authenticate(make_admin("+237600000973"))

        buffer = io.BytesIO()
        Image.new("RGB", (10, 10), color="green").save(buffer, format="JPEG")
        buffer.seek(0)
        buffer.name = "photo.jpg"
        upload_response = client.post(
            f"/api/admin/listings/{listing.id}/upload_media/",
            {"media_type": "photo", "file": buffer, "order": 0},
            format="multipart",
        )
        media_path = ListingMedia.objects.get(id=upload_response.data["id"]).file.path
        assert os.path.exists(media_path)

        response = client.delete(f"/api/admin/users/{owner.id}/")

        assert response.status_code == 204
        assert not User.objects.filter(id=owner.id).exists()
        assert not Listing.objects.filter(id=listing.id).exists()
        assert not os.path.exists(media_path)

    def test_admin_cannot_delete_own_account(self):
        admin = make_admin("+237600000974")
        client = APIClient()
        client.force_authenticate(admin)

        response = client.delete(f"/api/admin/users/{admin.id}/")

        assert response.status_code == 400
        assert User.objects.filter(id=admin.id).exists()

    def test_non_admin_cannot_delete_user(self):
        target = make_locataire("+237600000975")
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000976"))

        response = client.delete(f"/api/admin/users/{target.id}/")

        assert response.status_code == 403
        assert User.objects.filter(id=target.id).exists()


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
