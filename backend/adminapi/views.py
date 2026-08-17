from datetime import timedelta

from django.db.models import Count
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework import filters, pagination, parsers, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from adminapi.serializers import AdminInvitationSerializer, AdminListingSerializer, AdminReportSerializer
from invitations.models import Invitation
from invitations.services import create_invitation
from listings.models import Listing
from listings.serializers import ListingMediaSerializer
from reports.models import Report
from users.models import User
from users.permissions import IsAdminRole
from users.serializers import UserSerializer

TREND_DAYS = 14


def _daily_counts(queryset, date_field="created_at"):
    """Retourne le nombre d'enregistrements par jour sur les TREND_DAYS derniers
    jours (jours manquants inclus à 0), pour alimenter les graphiques du tableau de bord."""
    since = timezone.now() - timedelta(days=TREND_DAYS - 1)
    counts = {
        row["day"]: row["count"]
        for row in queryset.filter(**{f"{date_field}__gte": since})
        .annotate(day=TruncDate(date_field))
        .order_by()
        .values("day")
        .annotate(count=Count("id"))
    }
    today = timezone.localdate()
    return [
        {"date": (today - timedelta(days=offset)).isoformat(), "count": counts.get(today - timedelta(days=offset), 0)}
        for offset in range(TREND_DAYS - 1, -1, -1)
    ]


class AdminPageNumberPagination(pagination.PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class DashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get(self, request):
        return Response({
            "clients_count": User.objects.filter(role=User.Role.LOCATAIRE).count(),
            "annonceurs_count": User.objects.filter(role=User.Role.ANNONCEUR).count(),
            "listings_pending_count": Listing.objects.filter(status=Listing.Status.EN_ATTENTE).count(),
            "listings_published_count": Listing.objects.filter(status=Listing.Status.PUBLIEE).count(),
            "reports_open_count": Report.objects.filter(status=Report.Status.OUVERT).count(),
            "listings_published_by_day": _daily_counts(Listing.objects.all()),
            "signups_by_day": _daily_counts(User.objects.all(), date_field="date_joined"),
        })


class AdminListingViewSet(viewsets.ModelViewSet):
    """Modération : toutes les annonces, tous annonceurs confondus."""

    serializer_class = AdminListingSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    pagination_class = AdminPageNumberPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["title", "neighborhood", "owner__full_name", "owner__email", "owner__phone_number"]
    ordering_fields = ["created_at", "rent_amount", "title"]
    ordering = ["-created_at"]

    def get_queryset(self):
        qs = Listing.objects.select_related("owner").prefetch_related("media", "amenities")
        status_param = self.request.query_params.get("status")
        if status_param:
            qs = qs.filter(status=status_param)
        return qs

    def perform_create(self, serializer):
        # Annonce d'amorçage créée par l'admin : pas d'annonceur inscrit à ce stade.
        serializer.save(source=Listing.Source.AMORCE, status=Listing.Status.PUBLIEE)

    @action(detail=True, methods=["post"], parser_classes=[parsers.MultiPartParser])
    def upload_media(self, request, pk=None):
        listing = self.get_object()
        serializer = ListingMediaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(listing=listing)
        return Response(serializer.data, status=201)

    @action(detail=True, methods=["post"])
    def approve(self, request, pk=None):
        listing = self.get_object()
        listing.status = Listing.Status.PUBLIEE
        listing.save(update_fields=["status"])
        return Response(AdminListingSerializer(listing).data)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        listing = self.get_object()
        listing.status = Listing.Status.REJETEE
        listing.save(update_fields=["status"])
        return Response(AdminListingSerializer(listing).data)


class AdminUserViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    pagination_class = AdminPageNumberPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["full_name", "email", "phone_number"]
    ordering_fields = ["date_joined", "full_name"]
    ordering = ["-date_joined"]

    def get_queryset(self):
        qs = User.objects.all()
        role = self.request.query_params.get("role")
        if role:
            qs = qs.filter(role=role)
        return qs


class AdminInvitationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminInvitationSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    pagination_class = AdminPageNumberPagination
    queryset = Invitation.objects.select_related("listing").order_by("-created_at")

    def create(self, request, *args, **kwargs):
        phone_number = request.data.get("phone_number")
        listing_id = request.data.get("listing_id")
        if not phone_number:
            return Response({"detail": "phone_number est requis."}, status=400)

        listing = None
        if listing_id:
            listing = Listing.objects.filter(id=listing_id).first()
            if listing is None:
                return Response({"detail": "Annonce introuvable."}, status=404)

        invitation = create_invitation(phone_number, listing=listing, created_by=request.user)
        return Response(AdminInvitationSerializer(invitation).data, status=201)


class AdminReportViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminReportSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
    pagination_class = AdminPageNumberPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["listing__title", "reporter__email", "reporter__phone_number", "description"]
    ordering_fields = ["created_at"]
    ordering = ["-created_at"]

    def get_queryset(self):
        qs = Report.objects.select_related("listing", "reporter")
        status_param = self.request.query_params.get("status")
        if status_param:
            qs = qs.filter(status=status_param)
        return qs

    @action(detail=True, methods=["post"])
    def resolve(self, request, pk=None):
        report = self.get_object()
        new_status = request.data.get("status")
        if new_status not in [Report.Status.TRAITE, Report.Status.REJETE]:
            return Response({"detail": "status doit être 'traite' ou 'rejete'."}, status=400)
        report.status = new_status
        report.save(update_fields=["status"])
        return Response(AdminReportSerializer(report).data)
