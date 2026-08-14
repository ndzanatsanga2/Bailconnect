from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path
from django.views.generic import RedirectView

admin.site.site_header = "Bailconnect Admin"
admin.site.site_title = "Bailconnect Admin"
admin.site.index_title = "Vue d'ensemble"

urlpatterns = [
    path("", RedirectView.as_view(url="/admin/", permanent=False)),
    path("admin/", admin.site.urls),
    path("api/auth/", include("users.urls")),
    path("api/", include("listings.urls")),
    path("api/invitations/", include("invitations.urls")),
    path("api/leads/", include("leads.urls")),
    path("api/admin/", include("adminapi.urls")),
]

if settings.STORAGE_BACKEND != "s3":
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
