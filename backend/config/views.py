import hmac

from django.conf import settings
from django.core.management import call_command
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView


class RunListingMaintenanceView(APIView):
    """Exécute expire_stale_listings puis archive_expired_listings (section
    E : relance/archivage automatique des annonces) — déclenché par un cron
    externe gratuit (voir .github/workflows/listing-maintenance.yml), le
    plan free de Render ne supportant pas les services "cron" natifs.

    Protégé par un jeton partagé (header X-Maintenance-Token) plutôt que
    par l'authentification utilisateur habituelle : l'appelant n'est pas un
    compte Bailconnect mais un job planifié externe."""

    permission_classes = [AllowAny]

    def post(self, request):
        token = request.headers.get("X-Maintenance-Token", "")
        if not settings.MAINTENANCE_TOKEN or not hmac.compare_digest(token, settings.MAINTENANCE_TOKEN):
            return Response({"detail": "Non autorisé."}, status=401)
        call_command("expire_stale_listings")
        call_command("archive_expired_listings")
        return Response({"detail": "ok"})
