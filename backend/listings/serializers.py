from django.utils import timezone
from rest_framework import serializers

from listings.models import Amenity, Favorite, Listing, ListingMedia


class AmenitySerializer(serializers.ModelSerializer):
    class Meta:
        model = Amenity
        fields = ["id", "name", "icon"]


class ListingMediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListingMedia
        fields = ["id", "media_type", "file", "order", "duration_seconds", "created_at"]
        read_only_fields = ["id", "created_at"]


class ListingSerializer(serializers.ModelSerializer):
    media = ListingMediaSerializer(many=True, read_only=True)
    amenities = AmenitySerializer(many=True, read_only=True)
    amenity_ids = serializers.PrimaryKeyRelatedField(
        source="amenities", queryset=Amenity.objects.all(), many=True, write_only=True, required=False
    )

    class Meta:
        model = Listing
        fields = [
            "id", "owner", "title", "description", "neighborhood", "property_type",
            "rent_amount", "deposit_amount", "terms", "whatsapp_number",
            "amenities", "amenity_ids", "media", "status", "source", "verified",
            "last_confirmed_at", "expires_at", "created_at", "updated_at",
        ]
        read_only_fields = [
            "id", "owner", "status", "source", "verified",
            "last_confirmed_at", "expires_at", "created_at", "updated_at",
        ]

    def create(self, validated_data):
        validated_data["owner"] = self.context["request"].user
        validated_data["status"] = Listing.Status.EN_ATTENTE
        validated_data["source"] = Listing.Source.ANNONCEUR
        return super().create(validated_data)


class PublicListingSerializer(serializers.ModelSerializer):
    """Fil / recherche / fiche bien côté client — ne révèle jamais le
    contact WhatsApp (voir leads.views, qui le renvoie après création du Lead)."""

    media = ListingMediaSerializer(many=True, read_only=True)
    amenities = AmenitySerializer(many=True, read_only=True)
    is_favorite = serializers.SerializerMethodField()
    days_since_confirmed = serializers.SerializerMethodField()

    class Meta:
        model = Listing
        fields = [
            "id", "title", "description", "neighborhood", "property_type",
            "rent_amount", "deposit_amount", "terms",
            "amenities", "media", "verified", "days_since_confirmed",
            "is_favorite", "created_at",
        ]

    def get_is_favorite(self, obj) -> bool:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if not user or not user.is_authenticated:
            return False
        return obj.favorited_by.filter(user=user).exists()

    def get_days_since_confirmed(self, obj) -> int:
        reference = obj.last_confirmed_at or obj.created_at
        return (timezone.now() - reference).days


class FavoriteSerializer(serializers.ModelSerializer):
    listing = PublicListingSerializer(read_only=True)
    listing_id = serializers.PrimaryKeyRelatedField(
        source="listing",
        queryset=Listing.objects.filter(status=Listing.Status.PUBLIEE),
        write_only=True,
    )

    class Meta:
        model = Favorite
        fields = ["id", "listing", "listing_id", "created_at"]
        read_only_fields = ["id", "created_at"]
