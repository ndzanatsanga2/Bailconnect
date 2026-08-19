import io
from datetime import timedelta

import pytest
from django.core.management import call_command
from django.utils import timezone
from PIL import Image
from rest_framework.test import APIClient

from listings.models import Amenity, Listing
from users.models import User

pytestmark = pytest.mark.django_db


def make_annonceur(phone="+237600000100"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ANNONCEUR)


def make_locataire(phone="+237600000101"):
    return User.objects.create_user(phone_number=phone, role=User.Role.LOCATAIRE)


def listing_payload(**overrides):
    payload = {
        "title": "Studio meublé moderne",
        "description": "Proche du marché.",
        "neighborhood": "Bastos",
        "property_type": Listing.PropertyType.STUDIO,
        "rent_amount": 75000,
        "deposit_amount": 150000,
        "terms": "Caution 2 mois",
        "whatsapp_number": "+237600000200",
    }
    payload.update(overrides)
    return payload


class TestListingCreation:
    def test_annonceur_can_create_listing(self):
        annonceur = make_annonceur()
        client = APIClient()
        client.force_authenticate(annonceur)

        response = client.post("/api/listings/", listing_payload())

        assert response.status_code == 201
        assert response.data["status"] == Listing.Status.EN_ATTENTE
        assert response.data["source"] == Listing.Source.ANNONCEUR
        listing = Listing.objects.get(id=response.data["id"])
        assert listing.owner == annonceur

    def test_locataire_cannot_create_listing(self):
        client = APIClient()
        client.force_authenticate(make_locataire())

        response = client.post("/api/listings/", listing_payload())

        assert response.status_code == 403

    def test_unauthenticated_cannot_create_listing(self):
        client = APIClient()
        response = client.post("/api/listings/", listing_payload())
        assert response.status_code == 401


class TestListingScoping:
    def test_annonceur_only_sees_own_listings(self):
        annonceur_a = make_annonceur("+237600000110")
        annonceur_b = make_annonceur("+237600000111")
        client = APIClient()

        client.force_authenticate(annonceur_a)
        client.post("/api/listings/", listing_payload(title="Bien A"))

        client.force_authenticate(annonceur_b)
        client.post("/api/listings/", listing_payload(title="Bien B"))

        response = client.get("/api/listings/")
        titles = [item["title"] for item in response.data]
        assert titles == ["Bien B"]

    def test_annonceur_cannot_update_others_listing(self):
        owner = make_annonceur("+237600000120")
        other = make_annonceur("+237600000121")
        client = APIClient()
        client.force_authenticate(owner)
        created = client.post("/api/listings/", listing_payload()).data

        client.force_authenticate(other)
        response = client.patch(f"/api/listings/{created['id']}/", {"title": "Piraté"})

        assert response.status_code == 404  # hors du queryset scopé au propriétaire


class TestListingMediaUpload:
    def _image_file(self):
        buffer = io.BytesIO()
        Image.new("RGB", (10, 10), color="green").save(buffer, format="JPEG")
        buffer.seek(0)
        buffer.name = "photo.jpg"
        return buffer

    def test_owner_can_upload_media(self):
        annonceur = make_annonceur("+237600000130")
        client = APIClient()
        client.force_authenticate(annonceur)
        listing = client.post("/api/listings/", listing_payload()).data

        response = client.post(
            f"/api/listings/{listing['id']}/upload_media/",
            {"media_type": "photo", "file": self._image_file(), "order": 0},
            format="multipart",
        )

        assert response.status_code == 201
        assert Listing.objects.get(id=listing["id"]).media.count() == 1

    def test_non_owner_cannot_upload_media(self):
        owner = make_annonceur("+237600000140")
        other = make_annonceur("+237600000141")
        client = APIClient()
        client.force_authenticate(owner)
        listing = client.post("/api/listings/", listing_payload()).data

        client.force_authenticate(other)
        response = client.post(
            f"/api/listings/{listing['id']}/upload_media/",
            {"media_type": "photo", "file": self._image_file(), "order": 0},
            format="multipart",
        )

        assert response.status_code == 404

    def test_upload_media_response_returns_absolute_file_url(self):
        """Le front construit l'URL directement depuis ce champ — une URL
        relative y produirait une image cassée."""
        annonceur = make_annonceur("+237600000142")
        client = APIClient()
        client.force_authenticate(annonceur)
        listing = client.post("/api/listings/", listing_payload()).data

        response = client.post(
            f"/api/listings/{listing['id']}/upload_media/",
            {"media_type": "photo", "file": self._image_file(), "order": 0},
            format="multipart",
        )

        assert response.data["file"].startswith("http://testserver/")


class TestAmenityList:
    def test_amenity_list_is_public(self):
        Amenity.objects.create(name="Climatisation")
        client = APIClient()
        response = client.get("/api/amenities/")
        assert response.status_code == 200
        assert len(response.data) == 1


def make_published_listing(owner=None, **overrides):
    defaults = dict(
        title="Studio meublé moderne",
        neighborhood="Bastos",
        property_type=Listing.PropertyType.STUDIO,
        rent_amount=75000,
        whatsapp_number="+237600000200",
        status=Listing.Status.PUBLIEE,
    )
    defaults.update(overrides)
    return Listing.objects.create(owner=owner, **defaults)


class TestFeed:
    def test_feed_is_public_and_excludes_pending_listings(self):
        owner = make_annonceur("+237600000150")
        make_published_listing(owner=owner, title="Publiée")
        Listing.objects.create(
            owner=owner, title="En attente", neighborhood="Bastos",
            property_type=Listing.PropertyType.STUDIO, rent_amount=50000,
            whatsapp_number="+237600000201", status=Listing.Status.EN_ATTENTE,
        )

        response = APIClient().get("/api/feed/")

        assert response.status_code == 200
        titles = [item["title"] for item in response.data]
        assert titles == ["Publiée"]

    def test_feed_never_exposes_whatsapp_number(self):
        make_published_listing(owner=make_annonceur("+237600000151"))
        response = APIClient().get("/api/feed/")
        assert "whatsapp_number" not in response.data[0]

    def test_feed_filters_by_budget_max(self):
        owner = make_annonceur("+237600000152")
        make_published_listing(owner=owner, title="Abordable", rent_amount=50000)
        make_published_listing(owner=owner, title="Cher", rent_amount=300000)

        response = APIClient().get("/api/feed/", {"budget_max": 100000})

        titles = [item["title"] for item in response.data]
        assert titles == ["Abordable"]

    def test_feed_without_budget_max_returns_all_listings(self):
        owner = make_annonceur("+237600000154")
        make_published_listing(owner=owner, title="Abordable", rent_amount=50000)
        make_published_listing(owner=owner, title="Cher", rent_amount=300000)

        response = APIClient().get("/api/feed/")

        titles = {item["title"] for item in response.data}
        assert titles == {"Abordable", "Cher"}

    def test_feed_rejects_non_numeric_budget_max(self):
        owner = make_annonceur("+237600000155")
        make_published_listing(owner=owner, rent_amount=50000)

        response = APIClient().get("/api/feed/", {"budget_max": "gratuit"})

        assert response.status_code == 400
        assert "budget_max" in response.data

    def test_feed_filters_by_neighborhood(self):
        owner = make_annonceur("+237600000153")
        make_published_listing(owner=owner, title="Bastos", neighborhood="Bastos")
        make_published_listing(owner=owner, title="Odza", neighborhood="Odza")

        response = APIClient().get("/api/feed/", {"neighborhood": "Odza"})

        titles = [item["title"] for item in response.data]
        assert titles == ["Odza"]

    def test_feed_media_file_url_is_absolute(self):
        """Le front (feed_screen.dart, listing_detail_screen.dart) utilise ce
        champ tel quel comme source d'image — une URL relative ou une URL
        déjà absolue reconcaténée avec l'origine de l'API y produirait une
        image cassée (dégradé de secours affiché en permanence)."""
        owner = make_annonceur("+237600000156")
        listing = make_published_listing(owner=owner)
        client = APIClient()
        client.force_authenticate(owner)
        buffer = io.BytesIO()
        Image.new("RGB", (10, 10), color="blue").save(buffer, format="JPEG")
        buffer.seek(0)
        buffer.name = "photo.jpg"
        client.post(
            f"/api/listings/{listing.id}/upload_media/",
            {"media_type": "photo", "file": buffer, "order": 0},
            format="multipart",
        )

        response = APIClient().get("/api/feed/")

        file_url = response.data[0]["media"][0]["file"]
        assert file_url.startswith("http://testserver/")


class TestFavorites:
    def test_locataire_can_favorite_and_list(self):
        listing = make_published_listing(owner=make_annonceur("+237600000160"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000161"))

        create_response = client.post("/api/favorites/", {"listing_id": listing.id})
        assert create_response.status_code == 201

        list_response = client.get("/api/favorites/")
        assert len(list_response.data) == 1
        assert list_response.data[0]["listing"]["id"] == listing.id

    def test_feed_reflects_favorite_state_for_authenticated_user(self):
        listing = make_published_listing(owner=make_annonceur("+237600000162"))
        client = APIClient()
        tenant = make_locataire("+237600000163")
        client.force_authenticate(tenant)
        client.post("/api/favorites/", {"listing_id": listing.id})

        response = client.get("/api/feed/")

        assert response.data[0]["is_favorite"] is True

    def test_unauthenticated_cannot_access_favorites(self):
        response = APIClient().get("/api/favorites/")
        assert response.status_code == 401

    def test_locataire_can_remove_favorite(self):
        listing = make_published_listing(owner=make_annonceur("+237600000164"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000165"))
        favorite_id = client.post("/api/favorites/", {"listing_id": listing.id}).data["id"]

        response = client.delete(f"/api/favorites/{favorite_id}/")

        assert response.status_code == 204
        assert client.get("/api/favorites/").data == []

    def test_favoriting_twice_is_idempotent(self):
        listing = make_published_listing(owner=make_annonceur("+237600000166"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000167"))

        first = client.post("/api/favorites/", {"listing_id": listing.id})
        second = client.post("/api/favorites/", {"listing_id": listing.id})

        assert first.status_code == 201
        assert second.status_code == 201
        assert first.data["id"] == second.data["id"]
        assert len(client.get("/api/favorites/").data) == 1

    def test_locataire_can_remove_favorite_by_listing_id(self):
        listing = make_published_listing(owner=make_annonceur("+237600000168"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000169"))
        client.post("/api/favorites/", {"listing_id": listing.id})

        response = client.delete(f"/api/favorites/by-listing/{listing.id}/")

        assert response.status_code == 204
        assert client.get("/api/favorites/").data == []

    def test_remove_favorite_by_listing_id_when_not_favorited_returns_404(self):
        listing = make_published_listing(owner=make_annonceur("+237600000171"))
        client = APIClient()
        client.force_authenticate(make_locataire("+237600000172"))

        response = client.delete(f"/api/favorites/by-listing/{listing.id}/")

        assert response.status_code == 404


class TestListingFreshness:
    def test_owner_can_confirm_available_and_it_refreshes_and_unexpires(self):
        owner = make_annonceur("+237600000170")
        listing = make_published_listing(
            owner=owner, status=Listing.Status.EXPIREE,
            last_confirmed_at=timezone.now() - timedelta(days=30),
        )
        client = APIClient()
        client.force_authenticate(owner)

        response = client.post(f"/api/listings/{listing.id}/confirm_available/")

        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == Listing.Status.PUBLIEE
        assert listing.last_confirmed_at > timezone.now() - timedelta(minutes=1)

    def test_non_owner_cannot_confirm_available(self):
        listing = make_published_listing(owner=make_annonceur("+237600000171"))
        client = APIClient()
        client.force_authenticate(make_annonceur("+237600000172"))

        response = client.post(f"/api/listings/{listing.id}/confirm_available/")

        assert response.status_code == 404

    def test_owner_can_mark_rented(self):
        owner = make_annonceur("+237600000173")
        listing = make_published_listing(owner=owner)
        client = APIClient()
        client.force_authenticate(owner)

        response = client.post(f"/api/listings/{listing.id}/mark_rented/")

        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.status == Listing.Status.LOUEE


class TestExpireStaleListingsCommand:
    def test_expires_listings_never_confirmed_past_threshold(self, settings):
        settings.LISTING_EXPIRY_DAYS = 7
        owner = make_annonceur("+237600000180")
        stale = make_published_listing(owner=owner, title="Stale", last_confirmed_at=None)
        Listing.objects.filter(id=stale.id).update(created_at=timezone.now() - timedelta(days=10))

        call_command("expire_stale_listings")

        stale.refresh_from_db()
        assert stale.status == Listing.Status.EXPIREE

    def test_expires_listings_confirmed_too_long_ago(self, settings):
        settings.LISTING_EXPIRY_DAYS = 7
        owner = make_annonceur("+237600000181")
        stale = make_published_listing(
            owner=owner, title="Stale confirmed",
            last_confirmed_at=timezone.now() - timedelta(days=8),
        )

        call_command("expire_stale_listings")

        stale.refresh_from_db()
        assert stale.status == Listing.Status.EXPIREE

    def test_does_not_expire_recently_confirmed_listings(self, settings):
        settings.LISTING_EXPIRY_DAYS = 7
        owner = make_annonceur("+237600000182")
        fresh = make_published_listing(
            owner=owner, title="Fresh",
            last_confirmed_at=timezone.now() - timedelta(days=1),
        )

        call_command("expire_stale_listings")

        fresh.refresh_from_db()
        assert fresh.status == Listing.Status.PUBLIEE

    def test_does_not_touch_non_published_listings(self, settings):
        settings.LISTING_EXPIRY_DAYS = 7
        owner = make_annonceur("+237600000183")
        pending = make_published_listing(
            owner=owner, title="Pending", status=Listing.Status.EN_ATTENTE, last_confirmed_at=None,
        )
        Listing.objects.filter(id=pending.id).update(created_at=timezone.now() - timedelta(days=30))

        call_command("expire_stale_listings")

        pending.refresh_from_db()
        assert pending.status == Listing.Status.EN_ATTENTE
