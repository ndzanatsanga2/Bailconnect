import logging
from abc import ABC, abstractmethod

from django.conf import settings

logger = logging.getLogger("bailconnect.sms")


class SMSProvider(ABC):
    @abstractmethod
    def send(self, phone_number: str, message: str) -> None:
        ...


class ConsoleSMSProvider(SMSProvider):
    """Fallback dev : n'envoie rien, affiche le message dans la console du serveur."""

    def send(self, phone_number: str, message: str) -> None:
        print(f"[SMS DEV] {phone_number}: {message}", flush=True)
        logger.info("SMS (console) -> %s: %s", phone_number, message)


class TwilioSMSProvider(SMSProvider):
    def __init__(self):
        from twilio.rest import Client

        self._client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
        self._from_number = settings.TWILIO_FROM_NUMBER

    def send(self, phone_number: str, message: str) -> None:
        self._client.messages.create(body=message, from_=self._from_number, to=phone_number)


def get_sms_provider() -> SMSProvider:
    if settings.SMS_PROVIDER == "twilio":
        return TwilioSMSProvider()
    return ConsoleSMSProvider()
