from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path

admin.site.site_header = "Bailconnect Admin (outil interne)"
admin.site.site_title = "Bailconnect Admin"
admin.site.index_title = "Debug interne — le back-office produit est dans l'app Flutter"

urlpatterns = [
    path("", lambda request: JsonResponse({"service": "bailconnect-api"})),
    path("api/auth/", include("users.urls")),
    path("api/", include("listings.urls")),
    path("api/invitations/", include("invitations.urls")),
    path("api/leads/", include("leads.urls")),
    path("api/reports/", include("reports.urls")),
    path("api/admin/", include("adminapi.urls")),
    path("api/messaging/", include("messaging.urls")),
]

# Django Admin : outil de debug interne réservé aux superusers, jamais lié
# depuis l'app produit. Désactivé par défaut en production (DEBUG=False) —
# activable explicitement via DJANGO_ADMIN_ENABLED pour du debug ponctuel.
if settings.ADMIN_ENABLED:
    urlpatterns.append(path(settings.ADMIN_URL_PATH, admin.site.urls))

if settings.STORAGE_BACKEND != "s3":
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
