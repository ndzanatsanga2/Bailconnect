from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.utils import timezone

from listings.models import Listing


class Command(BaseCommand):
    """Archive les annonces expirées depuis trop longtemps sans réponse.

    La relance elle-même est passive : une annonce EXPIREE reste visible,
    avec son bouton de confirmation, dans l'espace bailleur (voir
    FreshnessActions côté frontend) — ce n'est qu'en l'absence de réponse au
    bout de LISTING_ARCHIVE_AFTER_EXPIRY_DAYS jours supplémentaires que cette
    commande l'archive automatiquement.

    À exécuter périodiquement (cron / tâche planifiée), après
    expire_stale_listings :
        python manage.py archive_expired_listings
    """

    help = "Archive les annonces EXPIREE depuis LISTING_ARCHIVE_AFTER_EXPIRY_DAYS jours."

    def handle(self, *args, **options):
        threshold = timezone.now() - timedelta(days=settings.LISTING_ARCHIVE_AFTER_EXPIRY_DAYS)
        stale = Listing.objects.filter(status=Listing.Status.EXPIREE, updated_at__lt=threshold)
        count = stale.update(status=Listing.Status.ARCHIVEE, updated_at=timezone.now())
        self.stdout.write(self.style.SUCCESS(f"{count} annonce(s) archivée(s)."))
