from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db.models import Q
from django.utils import timezone

from listings.models import Listing


class Command(BaseCommand):
    """Expire les annonces publiées sans confirmation de disponibilité récente.

    À exécuter périodiquement (cron / tâche planifiée) :
        python manage.py expire_stale_listings
    """

    help = "Expire les annonces publiées non confirmées depuis LISTING_EXPIRY_DAYS jours."

    def handle(self, *args, **options):
        threshold = timezone.now() - timedelta(days=settings.LISTING_EXPIRY_DAYS)
        stale = Listing.objects.filter(status=Listing.Status.PUBLIEE).filter(
            Q(last_confirmed_at__lt=threshold)
            | Q(last_confirmed_at__isnull=True, created_at__lt=threshold)
        )
        count = stale.update(status=Listing.Status.EXPIREE)
        self.stdout.write(self.style.SUCCESS(f"{count} annonce(s) expirée(s)."))
