from abc import ABC, abstractmethod

import requests
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
    contrairement à DjangoEmailProvider en mode smtp.

    Utilise `requests` (pas urllib) avec des en-têtes explicites — un client
    HTTP trop minimal (User-Agent générique, Accept absent) peut se faire
    bloquer par la protection anti-bot Cloudflare qui protège l'API Resend
    (constaté en prod : 403 "error code: 1010" avant même d'atteindre
    l'application Resend)."""

    _ENDPOINT = "https://api.resend.com/emails"

    def send(self, to: str, subject: str, message: str) -> None:
        response = requests.post(
            self._ENDPOINT,
            json={
                "from": settings.DEFAULT_FROM_EMAIL,
                "to": [to],
                "subject": subject,
                "text": message,
            },
            headers={
                "Authorization": f"Bearer {settings.RESEND_API_KEY}",
                "Accept": "application/json",
                "User-Agent": "bailconnect-backend/1.0",
            },
            timeout=settings.EMAIL_TIMEOUT,
        )
        if not response.ok:
            raise RuntimeError(f"Resend a répondu {response.status_code}: {response.text}")


def get_email_provider() -> EmailProvider:
    if settings.EMAIL_PROVIDER == "resend":
        return ResendEmailProvider()
    return DjangoEmailProvider()
