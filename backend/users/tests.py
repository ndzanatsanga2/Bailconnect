from datetime import timedelta

import pytest
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.test import APIClient

from users.models import OTPCode, User
from users.services.otp import channel_for, generate_and_send_otp, verify_otp

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

    def test_channel_detection(self):
        assert channel_for("+237600000006") == OTPCode.Channel.SMS
        assert channel_for("user@example.com") == OTPCode.Channel.EMAIL

    def test_verify_by_email_succeeds(self):
        _, code = generate_and_send_otp("user@example.com")
        assert verify_otp("user@example.com", code) is True


class TestOTPEndpoints:
    def test_verify_by_phone_creates_user_and_returns_token(self):
        _, code = generate_and_send_otp("+237600000010")
        client = APIClient()
        response = client.post(
            "/api/auth/otp/verify/", {"phone_number": "+237600000010", "code": code}
        )
        assert response.status_code == 200
        assert response.data["token"]
        assert response.data["user"]["phone_number"] == "+237600000010"
        assert User.objects.filter(phone_number="+237600000010").exists()

    def test_verify_by_email_creates_user_and_returns_token(self):
        _, code = generate_and_send_otp("user@example.com")
        client = APIClient()
        response = client.post(
            "/api/auth/otp/verify/", {"email": "user@example.com", "code": code}
        )
        assert response.status_code == 200
        assert response.data["token"]
        assert response.data["user"]["email"] == "user@example.com"
        assert User.objects.filter(email="user@example.com").exists()

    def test_request_and_verify_tolerate_spaces_in_phone_number(self):
        client = APIClient()
        client.post("/api/auth/otp/request/", {"phone_number": "+237 600 000 012"})
        otp = OTPCode.objects.filter(identifier="+237600000012").latest("created_at")
        code = "000000"
        otp.set_code(code)
        otp.save(update_fields=["code_hash"])

        response = client.post(
            "/api/auth/otp/verify/", {"phone_number": "+237-600-000-012", "code": code}
        )

        assert response.status_code == 200
        assert User.objects.filter(phone_number="+237600000012").exists()

    def test_verify_with_invalid_code_returns_400(self):
        client = APIClient()
        client.post("/api/auth/otp/request/", {"phone_number": "+237600000011"})
        response = client.post(
            "/api/auth/otp/verify/", {"phone_number": "+237600000011", "code": "000000"}
        )
        assert response.status_code == 400

    def test_request_without_identifier_returns_400(self):
        client = APIClient()
        response = client.post("/api/auth/otp/request/", {})
        assert response.status_code == 400

    def test_request_with_invalid_email_returns_400(self):
        client = APIClient()
        response = client.post("/api/auth/otp/request/", {"email": "not-an-email"})
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

    def test_public_otp_verify_cannot_grant_admin_role(self):
        _, code = generate_and_send_otp("+237600000022")
        client = APIClient()
        response = client.post(
            "/api/auth/otp/verify/",
            {"phone_number": "+237600000022", "code": code, "role": "admin"},
        )
        assert response.status_code == 400


class TestUserIdentifiers:
    def test_user_can_be_created_with_email_only(self):
        user = User.objects.create_user(email="only-email@example.com")
        assert user.phone_number is None
        assert user.email == "only-email@example.com"

    def test_user_can_be_created_with_phone_only(self):
        user = User.objects.create_user(phone_number="+237600000030")
        assert user.email is None

    def test_create_user_without_any_identifier_raises(self):
        with pytest.raises(ValueError):
            User.objects.create_user()

    def test_db_constraint_rejects_user_without_identifier(self):
        with pytest.raises(IntegrityError), transaction.atomic():
            User.objects.bulk_create([User(role=User.Role.LOCATAIRE)])
