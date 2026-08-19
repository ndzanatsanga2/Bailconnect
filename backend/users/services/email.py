import json
import urllib.error
import urllib.request
from abc import ABC, abstractmethod

from django.conf import settings
from django.core.mail import send_mail


class EmailProvider(ABC):
    @abstractmethod
    def send(self, to: str, subject: str, message: str) -> None:
        ...


class DjangoEmailProvider(EmailProvider):
    """Délègue à django.core.mail — backend console en dev, SMTP en prod
    selon EMAIL_BACKEND (voir settings.EMAIL_PROVIDER)."""

    def send(self, to: str, subject: str, message: str) -> None:
        send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [to], fail_silently=False)


class ResendEmailProvider(EmailProvider):
    """Envoi via l'API HTTP de Resend (resend.com) — contourne le blocage/
    throttling SMTP sortant fréquent depuis les IP des plateformes cloud
    (ex. Gmail qui bloque silencieusement les connexions SMTP de Render),
    contrairement à DjangoEmailProvider en mode smtp."""

    _ENDPOINT = "https://api.resend.com/emails"

    def send(self, to: str, subject: str, message: str) -> None:
        payload = json.dumps({
            "from": settings.DEFAULT_FROM_EMAIL,
            "to": [to],
            "subject": subject,
            "text": message,
        }).encode("utf-8")
        request = urllib.request.Request(
            self._ENDPOINT,
            data=payload,
            method="POST",
            headers={
                "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                "Content-Type": "application/json",
            },
        )
        try:
            urllib.request.urlopen(request, timeout=settings.EMAIL_TIMEOUT)
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", "replace")
            raise RuntimeError(f"Resend a répondu {exc.code}: {body}") from exc


def get_email_provider() -> EmailProvider:
    if settings.EMAIL_PROVIDER == "resend":
        return ResendEmailProvider()
    return DjangoEmailProvider()
