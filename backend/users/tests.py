import pytest
from django.core.cache import cache
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.test import APIClient

from users.models import OTPCode, User
from users.services.otp import channel_for, generate_and_send_otp, verify_otp

pytestmark = pytest.mark.django_db

VALID_PASSWORD = "Correcth0rse9"


def _set_next_code(identifier: str, code: str):
    generate_and_send_otp(identifier)
    otp = OTPCode.objects.filter(identifier=identifier).latest("created_at")
    otp.set_code(code)
    otp.save(update_fields=["code_hash"])


def _register_client(client, *, phone="+237600000100", email="client@example.com", city="Bastos", full_name="Awa Client", password=VALID_PASSWORD):
    _set_next_code(phone, "111111")
    return client.post("/api/auth/register/", {
        "role": "locataire", "phone_number": phone, "email": email,
        "code": "111111", "full_name": full_name, "city": city,
        "password": password, "password_confirm": password,
    })


def _register_annonceur(client, *, phone="+237600000200", email="bailleur@example.com", whatsapp="+237600000201", annonceur_type="bailleur", full_name="Awa Bailleur", password=VALID_PASSWORD):
    _set_next_code(phone, "222222")
    return client.post("/api/auth/register/", {
        "role": "annonceur", "phone_number": phone, "email": email,
        "code": "222222", "full_name": full_name, "whatsapp_number": whatsapp, "annonceur_type": annonceur_type,
        "password": password, "password_confirm": password,
    })


class TestOTPService:
    def test_verify_with_correct_code_succeeds(self):
        _, code = generate_and_send_otp("+237600000001")
        assert verify_otp("+237600000001", code) is True

    def test_verify_with_wrong_code_fails(self):
        generate_and_send_otp("+237600000002")
        assert verify_otp("+237600000002", "000000") is False

    def test_verify_with_expired_code_fails(self):
        from datetime import timedelta

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

    def test_verify_by_email_with_wrong_code_fails(self):
        generate_and_send_otp("wrong-code@example.com")
        assert verify_otp("wrong-code@example.com", "000000") is False

    def test_verify_by_email_with_expired_code_fails(self):
        from datetime import timedelta

        otp, code = generate_and_send_otp("expired@example.com")
        otp.expires_at = timezone.now() - timedelta(minutes=1)
        otp.save(update_fields=["expires_at"])
        assert verify_otp("expired@example.com", code) is False


class TestDjangoEmailProvider:
    def test_send_populates_outbox_with_recipient_and_subject(self, mailoutbox):
        from users.services.email import DjangoEmailProvider

        DjangoEmailProvider().send("dest@example.com", "Votre code Bailconnect", "Message du corps")

        assert len(mailoutbox) == 1
        sent = mailoutbox[0]
        assert sent.to == ["dest@example.com"]
        assert sent.subject == "Votre code Bailconnect"
        assert "Message du corps" in sent.body


class TestResendEmailProvider:
    def test_send_posts_expected_payload_to_resend_api(self, settings):
        from unittest.mock import MagicMock, patch

        from users.services.email import ResendEmailProvider

        settings.RESEND_API_KEY = "re_test_key"
        settings.DEFAULT_FROM_EMAIL = "Bailconnect <onboarding@resend.dev>"
        settings.EMAIL_TIMEOUT = 10

        mock_response = MagicMock(ok=True)
        with patch("users.services.email.requests.post", return_value=mock_response) as mock_post:
            ResendEmailProvider().send("dest@example.com", "Votre code Bailconnect", "Message du corps")

        assert mock_post.call_count == 1
        args, kwargs = mock_post.call_args
        assert args[0] == "https://api.resend.com/emails"
        assert kwargs["json"] == {
            "from": "Bailconnect <onboarding@resend.dev>",
            "to": ["dest@example.com"],
            "subject": "Votre code Bailconnect",
            "text": "Message du corps",
        }
        assert kwargs["headers"]["Authorization"] == "Bearer re_test_key"
        assert kwargs["timeout"] == 10

    def test_send_raises_when_response_is_not_ok(self, settings):
        from unittest.mock import MagicMock, patch

        from users.services.email import ResendEmailProvider

        settings.RESEND_API_KEY = "re_test_key"

        mock_response = MagicMock(ok=False, status_code=403, text='error code: 1010')
        with patch("users.services.email.requests.post", return_value=mock_response):
            with pytest.raises(RuntimeError, match="403"):
                ResendEmailProvider().send("dest@example.com", "Sujet", "Corps")


class TestOTPRequestEndpoint:
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


class TestOTPRequestThrottle:
    def setup_method(self):
        cache.clear()

    def teardown_method(self):
        cache.clear()

    def test_repeated_requests_for_same_identifier_get_throttled(self):
        client = APIClient()
        identifier = "throttle-target@example.com"

        for _ in range(5):
            response = client.post("/api/auth/otp/request/", {"email": identifier})
            assert response.status_code == 200

        response = client.post("/api/auth/otp/request/", {"email": identifier})

        assert response.status_code == 429
        assert "Trop de demandes" in response.data["detail"]

    def test_throttle_is_scoped_per_identifier(self):
        client = APIClient()
        for _ in range(5):
            client.post("/api/auth/otp/request/", {"email": "busy-target@example.com"})

        response = client.post("/api/auth/otp/request/", {"email": "other-target@example.com"})

        assert response.status_code == 200

    def test_requests_resume_after_the_window_clears(self):
        client = APIClient()
        identifier = "resumes-target@example.com"
        for _ in range(5):
            client.post("/api/auth/otp/request/", {"email": identifier})
        assert client.post("/api/auth/otp/request/", {"email": identifier}).status_code == 429

        cache.clear()  # simule l'expiration de la fenêtre glissante

        response = client.post("/api/auth/otp/request/", {"email": identifier})
        assert response.status_code == 200


class TestOTPRequestDoesNotBlock:
    """L'envoi effectif (SMTP/SMS) se fait dans un thread à part — la
    requête HTTP ne doit jamais attendre dessus, même si le fournisseur est
    lent ou échoue (cause du WORKER TIMEOUT observé en prod avec Gmail)."""

    def test_request_returns_immediately_even_if_provider_is_slow(self):
        import time
        from unittest.mock import patch

        class _SlowProvider:
            def send(self, *args, **kwargs):
                time.sleep(4)

        client = APIClient()
        with patch("users.services.otp.get_sms_provider", return_value=_SlowProvider()):
            start = time.monotonic()
            response = client.post("/api/auth/otp/request/", {"phone_number": "+237600000910"})
            elapsed = time.monotonic() - start

        assert response.status_code == 200
        assert elapsed < 2.0  # bien en dessous des 4s simulées — marge large contre le bruit machine

    def test_request_succeeds_even_if_provider_send_fails(self):
        from unittest.mock import patch

        class _FailingProvider:
            def send(self, *args, **kwargs):
                raise RuntimeError("boom")

        client = APIClient()
        with patch("users.services.otp.get_sms_provider", return_value=_FailingProvider()):
            response = client.post("/api/auth/otp/request/", {"phone_number": "+237600000911"})

        assert response.status_code == 200


class TestRegisterClient:
    def test_register_client_creates_locataire_with_all_fields(self):
        client = APIClient()
        response = _register_client(client)

        assert response.status_code == 201
        assert response.data["token"]
        user_data = response.data["user"]
        assert user_data["role"] == "locataire"
        assert user_data["is_annonceur"] is False
        assert user_data["city"] == "Bastos"
        assert "password" not in user_data

        user = User.objects.get(phone_number="+237600000100")
        assert user.check_password(VALID_PASSWORD)

    def test_register_client_requires_valid_city(self):
        client = APIClient()
        response = _register_client(client, city="Quartier inconnu")
        assert response.status_code == 400

    def test_register_with_mismatched_passwords_fails(self):
        client = APIClient()
        _set_next_code("+237600000104", "111111")
        response = client.post("/api/auth/register/", {
            "role": "locataire", "phone_number": "+237600000104", "email": "mismatch@example.com",
            "code": "111111", "full_name": "X", "city": "Odza",
            "password": VALID_PASSWORD, "password_confirm": "different-pass1",
        })
        assert response.status_code == 400

    def test_register_with_weak_password_fails(self):
        client = APIClient()
        _set_next_code("+237600000105", "111111")
        response = client.post("/api/auth/register/", {
            "role": "locataire", "phone_number": "+237600000105", "email": "weak@example.com",
            "code": "111111", "full_name": "X", "city": "Odza",
            "password": "12345678", "password_confirm": "12345678",
        })
        assert response.status_code == 400

    def test_register_with_wrong_code_fails(self):
        client = APIClient()
        _set_next_code("+237600000101", "111111")
        response = client.post("/api/auth/register/", {
            "role": "locataire", "phone_number": "+237600000101", "email": "wrongcode@example.com",
            "code": "000000", "full_name": "X", "city": "Odza",
            "password": VALID_PASSWORD, "password_confirm": VALID_PASSWORD,
        })
        assert response.status_code == 400

    def test_register_with_existing_phone_or_email_fails(self):
        client = APIClient()
        _register_client(client, phone="+237600000102", email="dup@example.com")
        response = _register_client(client, phone="+237600000102", email="autre@example.com")
        assert response.status_code == 400

    def test_register_client_via_email_channel_succeeds(self):
        client = APIClient()
        email = "email-channel@example.com"
        _set_next_code(email, "666666")

        response = client.post("/api/auth/register/", {
            "role": "locataire", "phone_number": "+237600000106", "email": email,
            "code": "666666", "otp_channel": "email", "full_name": "X", "city": "Odza",
            "password": VALID_PASSWORD, "password_confirm": VALID_PASSWORD,
        })

        assert response.status_code == 201
        assert User.objects.filter(email=email).exists()

    def test_register_with_email_channel_and_wrong_code_fails(self):
        client = APIClient()
        email = "email-channel-wrong@example.com"
        _set_next_code(email, "777777")

        response = client.post("/api/auth/register/", {
            "role": "locataire", "phone_number": "+237600000107", "email": email,
            "code": "000000", "otp_channel": "email", "full_name": "X", "city": "Odza",
            "password": VALID_PASSWORD, "password_confirm": VALID_PASSWORD,
        })

        assert response.status_code == 400
        assert not User.objects.filter(email=email).exists()

    def test_register_cannot_grant_admin_role(self):
        client = APIClient()
        _set_next_code("+237600000103", "111111")
        response = client.post("/api/auth/register/", {
            "role": "admin", "phone_number": "+237600000103", "email": "admin-try@example.com",
            "code": "111111", "full_name": "X",
            "password": VALID_PASSWORD, "password_confirm": VALID_PASSWORD,
        })
        assert response.status_code == 400


class TestRegisterAnnonceur:
    def test_register_annonceur_creates_account_with_whatsapp_and_type(self):
        client = APIClient()
        response = _register_annonceur(client)

        assert response.status_code == 201
        user_data = response.data["user"]
        assert user_data["role"] == "annonceur"
        assert user_data["is_annonceur"] is True
        assert user_data["whatsapp_number"] == "+237600000201"
        assert user_data["annonceur_type"] == "bailleur"

    def test_register_annonceur_requires_whatsapp_and_type(self):
        client = APIClient()
        _set_next_code("+237600000202", "111111")
        response = client.post("/api/auth/register/", {
            "role": "annonceur", "phone_number": "+237600000202", "email": "noannonceurfields@example.com",
            "code": "111111", "full_name": "X",
            "password": VALID_PASSWORD, "password_confirm": VALID_PASSWORD,
        })
        assert response.status_code == 400


class TestLogin:
    def test_login_by_email_with_correct_password_succeeds(self):
        client = APIClient()
        _register_client(client, phone="+237600000010", email="login1@example.com")

        response = client.post("/api/auth/login/", {"email": "login1@example.com", "password": VALID_PASSWORD})

        assert response.status_code == 200
        assert response.data["token"]

    def test_login_by_phone_with_correct_password_succeeds(self):
        client = APIClient()
        _register_client(client, phone="+237600000011", email="login2@example.com")

        response = client.post("/api/auth/login/", {"phone_number": "+237600000011", "password": VALID_PASSWORD})

        assert response.status_code == 200

    def test_login_with_wrong_password_fails_generically(self):
        client = APIClient()
        _register_client(client, phone="+237600000012", email="login3@example.com")

        response = client.post("/api/auth/login/", {"email": "login3@example.com", "password": "wrong-password1"})

        assert response.status_code == 400
        assert "incorrect" in response.data["detail"].lower()

    def test_login_with_unknown_identifier_fails_with_same_generic_message(self):
        client = APIClient()
        response = client.post("/api/auth/login/", {"email": "nobody@example.com", "password": "whatever-123"})
        assert response.status_code == 400
        assert "incorrect" in response.data["detail"].lower()

    def test_repeated_failed_logins_lock_account(self):
        client = APIClient()
        _register_client(client, phone="+237600000013", email="login4@example.com")
        for _ in range(5):
            client.post("/api/auth/login/", {"email": "login4@example.com", "password": "wrong-password1"})

        response = client.post("/api/auth/login/", {"email": "login4@example.com", "password": VALID_PASSWORD})

        assert response.status_code == 423

    def test_successful_login_resets_failed_attempts(self):
        client = APIClient()
        _register_client(client, phone="+237600000014", email="login5@example.com")
        client.post("/api/auth/login/", {"email": "login5@example.com", "password": "wrong-password1"})

        response = client.post("/api/auth/login/", {"email": "login5@example.com", "password": VALID_PASSWORD})

        assert response.status_code == 200
        user = User.objects.get(email="login5@example.com")
        assert user.login_failed_attempts == 0
        assert user.login_locked_until is None


class TestPasswordReset:
    def test_reset_password_with_valid_otp_succeeds_and_can_login_with_new_password(self):
        client = APIClient()
        _register_client(client, phone="+237600000110", email="reset1@example.com")
        _set_next_code("reset1@example.com", "333333")

        new_password = "NewSecure-99"
        response = client.post("/api/auth/password/reset/confirm/", {
            "email": "reset1@example.com", "code": "333333",
            "new_password": new_password, "new_password_confirm": new_password,
        })

        assert response.status_code == 200
        assert response.data["token"]

        login_response = APIClient().post("/api/auth/login/", {"email": "reset1@example.com", "password": new_password})
        assert login_response.status_code == 200

        old_password_response = APIClient().post("/api/auth/login/", {"email": "reset1@example.com", "password": VALID_PASSWORD})
        assert old_password_response.status_code == 400

    def test_reset_password_with_invalid_code_fails(self):
        client = APIClient()
        _register_client(client, phone="+237600000111", email="reset2@example.com")

        response = client.post("/api/auth/password/reset/confirm/", {
            "email": "reset2@example.com", "code": "000000",
            "new_password": "NewSecure-99", "new_password_confirm": "NewSecure-99",
        })

        assert response.status_code == 400

    def test_reset_password_for_unknown_identifier_returns_404(self):
        client = APIClient()
        _set_next_code("unknown-reset@example.com", "444444")

        response = client.post("/api/auth/password/reset/confirm/", {
            "email": "unknown-reset@example.com", "code": "444444",
            "new_password": "NewSecure-99", "new_password_confirm": "NewSecure-99",
        })

        assert response.status_code == 404

    def test_reset_password_with_mismatched_confirmation_fails(self):
        client = APIClient()
        _register_client(client, phone="+237600000112", email="reset3@example.com")
        _set_next_code("reset3@example.com", "555555")

        response = client.post("/api/auth/password/reset/confirm/", {
            "email": "reset3@example.com", "code": "555555",
            "new_password": "NewSecure-99", "new_password_confirm": "Different-99",
        })

        assert response.status_code == 400


class TestBecomeAnnonceur:
    def test_locataire_can_add_annonceur_capacity(self):
        client = APIClient()
        register_response = _register_client(client, phone="+237600000300", email="upgrade@example.com")
        client.credentials(HTTP_AUTHORIZATION=f"Token {register_response.data['token']}")

        response = client.post("/api/auth/capacity/annonceur/", {
            "whatsapp_number": "+237600000301", "annonceur_type": "agent",
        })

        assert response.status_code == 200
        assert response.data["is_annonceur"] is True
        assert response.data["annonceur_type"] == "agent"
        assert response.data["role"] == "locataire"

    def test_unauthenticated_cannot_add_capacity(self):
        client = APIClient()
        response = client.post("/api/auth/capacity/annonceur/", {
            "whatsapp_number": "+237600000302", "annonceur_type": "agent",
        })
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
