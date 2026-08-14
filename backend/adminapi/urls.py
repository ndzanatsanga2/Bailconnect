from django.urls import include, path
from rest_framework.routers import DefaultRouter

from adminapi.views import (
    AdminInvitationViewSet,
    AdminListingViewSet,
    AdminReportViewSet,
    AdminUserViewSet,
    DashboardView,
)

router = DefaultRouter()
router.register("listings", AdminListingViewSet, basename="admin-listing")
router.register("users", AdminUserViewSet, basename="admin-user")
router.register("invitations", AdminInvitationViewSet, basename="admin-invitation")
router.register("reports", AdminReportViewSet, basename="admin-report")

urlpatterns = [
    path("dashboard/", DashboardView.as_view(), name="admin-dashboard"),
    path("", include(router.urls)),
]
