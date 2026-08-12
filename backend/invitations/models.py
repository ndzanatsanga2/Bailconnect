import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone

from leads.models import Lead
from listings.models import Listing


class Invitation(models.Model):
    """Lien unique de création de compte envoyé à un annonceur non inscrit
    (flux d'amorçage : le message brut n'est jamais transmis au locataire)."""

    token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    phone_number = models.CharField(max_length=20)
    listing = models.ForeignKey(
        Listing, on_delete=models.SET_NULL, null=True, blank=True, related_name="invitations"
    )
    lead = models.ForeignKey(
        Lead, on_delete=models.SET_NULL, null=True, blank=True, related_name="invitations"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="sent_invitations",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def is_expired(self) -> bool:
        return timezone.now() > self.expires_at

    def __str__(self):
        return f"Invitation {self.phone_number} ({'utilisée' if self.used_at else 'en attente'})"
