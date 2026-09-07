from datetime import timedelta
from unittest.mock import patch

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from listings.models import Listing
from users.models import User

pytestmark = pytest.mark.django_db

URL = "/api/internal/run-listing-maintenance/"


def make_annonceur(phone="+237600000980"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ANNONCEUR)


class TestRunListingMaintenanceEndpoint:
    def test_rejects_request_without_token(self, settings):
        settings.MAINTENANCE_TOKEN = "secret-token"
        response = APIClient().post(URL)
        assert response.status_code == 401

    def test_rejects_request_with_wrong_token(self, settings):
        settings.MAINTENANCE_TOKEN = "secret-token"
        response = APIClient().post(URL, HTTP_X_MAINTENANCE_TOKEN="wrong")
        assert response.status_code == 401

    def test_rejects_any_token_when_none_configured(self, settings):
        settings.MAINTENANCE_TOKEN = ""
        response = APIClient().post(URL, HTTP_X_MAINTENANCE_TOKEN="anything")
        assert response.status_code == 401

    def test_correct_token_runs_expiry_and_archival_commands(self, settings):
        settings.MAINTENANCE_TOKEN = "secret-token"
        settings.LISTING_ARCHIVE_AFTER_EXPIRY_DAYS = 14
        owner = make_annonceur()
        stale = Listing.objects.create(
            owner=owner, title="A", neighborhood="Bastos",
            property_type=Listing.PropertyType.STUDIO, rent_amount=50000,
            whatsapp_number="+237600001000", status=Listing.Status.PUBLIEE,
        )
        Listing.objects.filter(id=stale.id).update(created_at=timezone.now() - timedelta(days=30))
        expired = Listing.objects.create(
            owner=owner, title="B", neighborhood="Bastos",
            property_type=Listing.PropertyType.STUDIO, rent_amount=50000,
            whatsapp_number="+237600001000", status=Listing.Status.EXPIREE,
        )
        Listing.objects.filter(id=expired.id).update(updated_at=timezone.now() - timedelta(days=20))

        response = APIClient().post(URL, HTTP_X_MAINTENANCE_TOKEN="secret-token")

        assert response.status_code == 200
        stale.refresh_from_db()
        expired.refresh_from_db()
        assert stale.status == Listing.Status.EXPIREE
        assert expired.status == Listing.Status.ARCHIVEE

    def test_calls_both_management_commands(self, settings):
        settings.MAINTENANCE_TOKEN = "secret-token"
        with patch("config.views.call_command") as mock_call_command:
            response = APIClient().post(URL, HTTP_X_MAINTENANCE_TOKEN="secret-token")

        assert response.status_code == 200
        assert mock_call_command.call_args_list == [
            (("expire_stale_listings",),),
            (("archive_expired_listings",),),
        ]
