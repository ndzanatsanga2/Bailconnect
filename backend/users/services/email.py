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


def get_email_provider() -> EmailProvider:
    return DjangoEmailProvider()
