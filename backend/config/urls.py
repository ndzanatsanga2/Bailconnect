from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("users.urls")),
]

if settings.STORAGE_BACKEND != "s3":
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
