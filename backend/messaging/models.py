from django.conf import settings
from django.db import models

from listings.models import Listing


class Conversation(models.Model):
    """Discussion autour d'un bien entre le client intéressé et l'annonceur.

    Le champ `updated_at` (auto_now) sert à trier par activité récente sans
    dénormaliser le dernier message ; conçu pour pouvoir brancher plus tard
    un transport temps réel (WebSocket/Channels) sans changer ce modèle.
    """

    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="conversations")
    client = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="client_conversations")
    annonceur = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="annonceur_conversations")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["listing", "client", "annonceur"], name="unique_conversation_per_listing_pair"),
        ]
        ordering = ["-updated_at"]

    def __str__(self):
        return f"Conversation #{self.pk} — {self.listing} ({self.client} ↔ {self.annonceur})"


class Message(models.Model):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, related_name="messages")
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="sent_messages")
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Message #{self.pk} de {self.author} dans #{self.conversation_id}"
