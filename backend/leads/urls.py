from django.urls import include, path
from rest_framework.routers import DefaultRouter

from leads.views import LeadCreateView, ReceivedLeadViewSet

router = DefaultRouter()
router.register("received", ReceivedLeadViewSet, basename="lead-received")

urlpatterns = [
    path("", LeadCreateView.as_view(), name="lead-create"),
    path("", include(router.urls)),
]
