from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView

from adminapi.serializers import AdminInvitationSerializer, AdminListingSerializer, AdminReportSerializer
from invitations.models import Invitation
from invitations.services import create_invitation
from listings.models import Listing
from reports.models import Report
from users.models import User
from users.permissions import IsAdminRole
from users.serializers import UserSerializer


class DashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get(self, request):
        return Response({
            "clients_count": User.objects.filter(role=User.Role.LOCATAIRE).count(),
            "annonceurs_count": User.objects.filter(role=User.Role.ANNONCEUR).count(),
            "listings_pending_count": Listing.objects.filter(status=Listing.Status.EN_ATTENTE).count(),
            "listings_published_count": Listing.objects.filter(status=Listing.Status.PUBLIEE).count(),
            "reports_open_count": Report.objects.filter(status=Report.Status.OUVERT).count(),
        })


class AdminListingViewSet(viewsets.ModelViewSet):
    """Modération : toutes les annonces, tous annonceurs confondus."""

    serializer_class = AdminListingSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]

    def get_queryset(self):
        qs = Listing.objects.select_related("owner").prefetch_related("media", "amenities").order_by("-created_at")
        status_param = self.request.query_params.get("status")
        if status_param:
            qs = qs.filter(status=status_param)
        return qs

    def perform_create(self, serializer):
        # Annonce d'amorçage créée par l'admin : pas d'annonceur inscrit à ce stade.
        serializer.save(source=Listing.Source.AMORCE, status=Listing.Status.PUBLIEE)

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

    def get_queryset(self):
        qs = User.objects.all().order_by("-date_joined")
        role = self.request.query_params.get("role")
        if role:
            qs = qs.filter(role=role)
        return qs


class AdminInvitationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AdminInvitationSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminRole]
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

    def get_queryset(self):
        qs = Report.objects.select_related("listing", "reporter").order_by("-created_at")
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
