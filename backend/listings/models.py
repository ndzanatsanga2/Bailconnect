from django.conf import settings
from django.db import models


class Amenity(models.Model):
    name = models.CharField(max_length=50, unique=True)
    icon = models.CharField(max_length=50, blank=True)

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "amenities"

    def __str__(self):
        return self.name


class Listing(models.Model):
    class PropertyType(models.TextChoices):
        STUDIO = "studio", "Studio"
        APPARTEMENT = "appartement", "Appartement"
        CHAMBRE = "chambre", "Chambre"
        VILLA = "villa", "Villa"

    class Status(models.TextChoices):
        EN_ATTENTE = "en_attente", "En attente"
        PUBLIEE = "publiee", "Publiée"
        REJETEE = "rejetee", "Rejetée"
        LOUEE = "louee", "Louée"
        EXPIREE = "expiree", "Expirée"

    class Source(models.TextChoices):
        ANNONCEUR = "annonceur", "Annonceur"
        AMORCE = "amorce", "Amorçage"

    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="listings"
    )
    title = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    neighborhood = models.CharField(max_length=100, help_text="Quartier de Yaoundé")
    property_type = models.CharField(max_length=20, choices=PropertyType.choices)
    rent_amount = models.PositiveIntegerField(help_text="FCFA / mois")
    deposit_amount = models.PositiveIntegerField(default=0, help_text="FCFA")
    terms = models.TextField(blank=True, help_text="Modalités")
    whatsapp_number = models.CharField(max_length=20)
    amenities = models.ManyToManyField(Amenity, blank=True, related_name="listings")

    status = models.CharField(max_length=20, choices=Status.choices, default=Status.EN_ATTENTE)
    source = models.CharField(max_length=20, choices=Source.choices, default=Source.ANNONCEUR)
    verified = models.BooleanField(default=False, help_text="Badge « Vérifié Bailconnect »")

    # Amorçage : annonce publiée pour le compte d'un annonceur pas encore inscrit.
    # Le contact n'est jamais exposé publiquement (voir flux d'invitation).
    seed_contact_name = models.CharField(max_length=150, blank=True)
    seed_contact_phone = models.CharField(max_length=20, blank=True)

    last_confirmed_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title


class ListingMedia(models.Model):
    class MediaType(models.TextChoices):
        PHOTO = "photo", "Photo"
        VIDEO = "video", "Vidéo"

    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="media")
    media_type = models.CharField(max_length=10, choices=MediaType.choices)
    file = models.FileField(upload_to="listings/%Y/%m/")
    order = models.PositiveSmallIntegerField(default=0)
    duration_seconds = models.PositiveSmallIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order", "created_at"]
        verbose_name_plural = "listing media"

    def __str__(self):
        return f"{self.get_media_type_display()} · {self.listing.title}"


class Favorite(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="favorites"
    )
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="favorited_by")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "listing")
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user} ♥ {self.listing}"
