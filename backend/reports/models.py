from django.conf import settings
from django.db import models

from listings.models import Listing


class Report(models.Model):
    class Reason(models.TextChoices):
        FAUSSE_ANNONCE = "fausse_annonce", "Fausse annonce"
        DEJA_LOUE = "deja_loue", "Déjà loué"
        CONTENU_INAPPROPRIE = "contenu_inapproprie", "Contenu inapproprié"
        AUTRE = "autre", "Autre"

    class Status(models.TextChoices):
        OUVERT = "ouvert", "Ouvert"
        TRAITE = "traite", "Traité"
        REJETE = "rejete", "Rejeté"

    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="reports")
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reports"
    )
    reason = models.CharField(max_length=30, choices=Reason.choices)
    description = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OUVERT)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Signalement {self.listing} ({self.get_status_display()})"
