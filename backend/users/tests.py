from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from users.models import User
from users.services.otp import generate_and_send_otp, verify_otp

pytestmark = pytest.mark.django_db


class TestOTPService:
    def test_verify_with_correct_code_succeeds(self):
        _, code = generate_and_send_otp("+237600000001")
        assert verify_otp("+237600000001", code) is True

    def test_verify_with_wrong_code_fails(self):
        generate_and_send_otp("+237600000002")
        assert verify_otp("+237600000002", "000000") is False

    def test_verify_with_expired_code_fails(self):
        otp, code = generate_and_send_otp("+237600000003")
        otp.expires_at = timezone.now() - timedelta(minutes=1)
        otp.save(update_fields=["expires_at"])
        assert verify_otp("+237600000003", code) is False

    def test_code_cannot_be_reused(self):
        _, code = generate_and_send_otp("+237600000004")
        assert verify_otp("+237600000004", code) is True
        assert verify_otp("+237600000004", code) is False

    def test_verify_with_no_pending_code_fails(self):
        assert verify_otp("+237600000005", "123456") is False


class TestOTPEndpoints:
    def test_verify_creates_user_and_returns_token(self):
        _, code = generate_and_send_otp("+237600000010")
        client = APIClient()
        response = client.post(
            "/api/auth/otp/verify/", {"phone_number": "+237600000010", "code": code}
        )
        assert response.status_code == 200
        assert response.data["token"]
        assert response.data["user"]["phone_number"] == "+237600000010"
        assert User.objects.filter(phone_number="+237600000010").exists()

    def test_verify_with_invalid_code_returns_400(self):
        client = APIClient()
        client.post("/api/auth/otp/request/", {"phone_number": "+237600000011"})
        response = client.post(
            "/api/auth/otp/verify/", {"phone_number": "+237600000011", "code": "000000"}
        )
        assert response.status_code == 400

    def test_me_requires_authentication(self):
        client = APIClient()
        response = client.get("/api/auth/me/")
        assert response.status_code == 401


class TestRolePermissions:
    def test_role_choices_cover_expected_roles(self):
        assert set(User.Role.values) == {"locataire", "annonceur", "admin"}

    def test_default_role_is_locataire(self):
        user = User.objects.create_user(phone_number="+237600000020")
        assert user.role == User.Role.LOCATAIRE

    def test_admin_created_via_superuser_has_admin_role(self):
        admin = User.objects.create_superuser(phone_number="+237600000021", password="x")
        assert admin.role == User.Role.ADMIN
        assert admin.is_staff is True
        assert admin.is_superuser is True
