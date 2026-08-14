from rest_framework import serializers

from invitations.models import Invitation
from listings.models import Amenity, Listing
from reports.models import Report


class AdminListingSerializer(serializers.ModelSerializer):
    """Vue admin d'une annonce : tous les champs, y compris ceux réservés à
    l'amorçage (seed_contact_*), lecture et création complètes."""

    amenity_ids = serializers.PrimaryKeyRelatedField(
        source="amenities", queryset=Amenity.objects.all(), many=True, write_only=True, required=False
    )
    owner_display = serializers.SerializerMethodField()

    class Meta:
        model = Listing
        fields = [
            "id", "owner", "owner_display", "title", "description", "neighborhood", "property_type",
            "rent_amount", "deposit_amount", "terms", "whatsapp_number",
            "amenities", "amenity_ids", "status", "source", "verified",
            "seed_contact_name", "seed_contact_phone",
            "last_confirmed_at", "expires_at", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "owner", "amenities", "created_at", "updated_at"]

    def get_owner_display(self, obj) -> str:
        if obj.owner:
            return obj.owner.full_name or obj.owner.email or obj.owner.phone_number or f"#{obj.owner_id}"
        if obj.seed_contact_name:
            return f"{obj.seed_contact_name} (amorçage)"
        return "Amorçage"


class AdminInvitationSerializer(serializers.ModelSerializer):
    listing_title = serializers.CharField(source="listing.title", read_only=True)

    class Meta:
        model = Invitation
        fields = [
            "id", "phone_number", "listing", "listing_title",
            "created_at", "expires_at", "used_at",
        ]
        read_only_fields = fields


class AdminReportSerializer(serializers.ModelSerializer):
    listing_title = serializers.CharField(source="listing.title", read_only=True)
    reporter_identifier = serializers.SerializerMethodField()

    class Meta:
        model = Report
        fields = [
            "id", "listing", "listing_title", "reporter", "reporter_identifier",
            "reason", "description", "status", "created_at",
        ]
        read_only_fields = fields

    def get_reporter_identifier(self, obj) -> str:
        return obj.reporter.email or obj.reporter.phone_number or ""
