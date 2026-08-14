import secrets

from django.conf import settings

from users.models import OTPCode
from users.services.email import get_email_provider
from users.services.sms import get_sms_provider


def _generate_code(length: int) -> str:
    return "".join(str(secrets.randbelow(10)) for _ in range(length))


def channel_for(identifier: str) -> str:
    return OTPCode.Channel.EMAIL if "@" in identifier else OTPCode.Channel.SMS


def generate_and_send_otp(identifier: str) -> tuple[OTPCode, str]:
    channel = channel_for(identifier)
    code = _generate_code(settings.OTP_CODE_LENGTH)
    otp = OTPCode(
        identifier=identifier,
        channel=channel,
        expires_at=OTPCode.new_expiry(settings.OTP_EXPIRY_MINUTES),
    )
    otp.set_code(code)
    otp.save()

    message = f"Votre code Bailconnect : {code}"
    if channel == OTPCode.Channel.EMAIL:
        get_email_provider().send(identifier, "Votre code Bailconnect", message)
    else:
        get_sms_provider().send(identifier, message)

    return otp, code


def verify_otp(identifier: str, code: str) -> bool:
    otp = OTPCode.objects.filter(identifier=identifier, is_used=False).order_by("-created_at").first()
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
