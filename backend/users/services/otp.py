import secrets

from django.conf import settings

from users.models import OTPCode
from users.services.sms import get_sms_provider


def _generate_code(length: int) -> str:
    return "".join(str(secrets.randbelow(10)) for _ in range(length))


def generate_and_send_otp(phone_number: str) -> tuple[OTPCode, str]:
    code = _generate_code(settings.OTP_CODE_LENGTH)
    otp = OTPCode(
        phone_number=phone_number,
        expires_at=OTPCode.new_expiry(settings.OTP_EXPIRY_MINUTES),
    )
    otp.set_code(code)
    otp.save()
    get_sms_provider().send(phone_number, f"Votre code Bailconnect : {code}")
    return otp, code


def verify_otp(phone_number: str, code: str) -> bool:
    otp = OTPCode.objects.filter(phone_number=phone_number, is_used=False).order_by("-created_at").first()
    if otp is None:
        return False

    otp.attempts += 1
    otp.save(update_fields=["attempts"])

    if otp.attempts > settings.OTP_MAX_ATTEMPTS:
        return False
    if otp.is_expired():
        return False
    if not otp.check_code(code):
        return False

    otp.is_used = True
    otp.save(update_fields=["is_used"])
    return True
