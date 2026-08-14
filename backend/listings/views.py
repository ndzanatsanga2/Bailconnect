from django.utils import timezone
from rest_framework import parsers, permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from listings.models import Amenity, Favorite, Listing
from listings.serializers import (
    AmenitySerializer,
    FavoriteSerializer,
    ListingMediaSerializer,
    ListingSerializer,
    PublicListingSerializer,
)
from users.permissions import IsAnnonceur


class IsOwner(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.owner_id == request.user.id


class ListingViewSet(viewsets.ModelViewSet):
    """Gestion des biens de l'annonceur connecté (tableau de bord)."""

    serializer_class = ListingSerializer

    def get_permissions(self):
        if self.action == "create":
            return [permissions.IsAuthenticated(), IsAnnonceur()]
        if self.action in [
            "update", "partial_update", "destroy", "upload_media",
            "confirm_available", "mark_rented",
        ]:
            return [permissions.IsAuthenticated(), IsAnnonceur(), IsOwner()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        return (
            Listing.objects.filter(owner=self.request.user)
            .prefetch_related("media", "amenities")
        )

    @action(detail=True, methods=["post"], parser_classes=[parsers.MultiPartParser])
    def upload_media(self, request, pk=None):
        listing = self.get_object()
        serializer = ListingMediaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(listing=listing)
        return Response(serializer.data, status=201)

    @action(detail=True, methods=["post"])
    def confirm_available(self, request, pk=None):
        """« Toujours disponible » — rafraîchit la fraîcheur et réactive
        l'annonce si elle avait expiré."""
        listing = self.get_object()
        listing.last_confirmed_at = timezone.now()
        if listing.status == Listing.Status.EXPIREE:
            listing.status = Listing.Status.PUBLIEE
        listing.save(update_fields=["last_confirmed_at", "status"])
        return Response(ListingSerializer(listing).data)

    @action(detail=True, methods=["post"])
    def mark_rented(self, request, pk=None):
        listing = self.get_object()
        listing.status = Listing.Status.LOUEE
        listing.save(update_fields=["status"])
        return Response(ListingSerializer(listing).data)


class AmenityViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Amenity.objects.all()
    serializer_class = AmenitySerializer
    permission_classes = [permissions.AllowAny]


class FeedViewSet(viewsets.ReadOnlyModelViewSet):
    """Fil public — consultable sans connexion (spec point 2)."""

    serializer_class = PublicListingSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = (
            Listing.objects.filter(status=Listing.Status.PUBLIEE)
            .prefetch_related("media", "amenities")
        )
        params = self.request.query_params

        neighborhood = params.get("neighborhood")
        if neighborhood:
            qs = qs.filter(neighborhood__icontains=neighborhood)

        budget_max = params.get("budget_max")
        if budget_max:
            qs = qs.filter(rent_amount__lte=budget_max)

        property_type = params.get("property_type")
        if property_type:
            qs = qs.filter(property_type=property_type)

        amenity_ids = params.getlist("amenity")
        if amenity_ids:
            qs = qs.filter(amenities__id__in=amenity_ids)

        media_type = params.get("media")
        if media_type in ("video", "photo"):
            qs = qs.filter(media__media_type=media_type)

        return qs.distinct().order_by("-created_at")


class FavoriteViewSet(viewsets.ModelViewSet):
    http_method_names = ["get", "post", "delete", "head", "options"]
    serializer_class = FavoriteSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return (
            Favorite.objects.filter(user=self.request.user)
            .select_related("listing")
            .prefetch_related("listing__media", "listing__amenities")
        )

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
