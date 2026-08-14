from rest_framework import serializers

from leads.models import Lead


class ReceivedLeadSerializer(serializers.ModelSerializer):
    """Demande reçue côté annonceur — vue sur un Lead pour le bien concerné."""

    listing_id = serializers.IntegerField(source="listing.id", read_only=True)
    listing_title = serializers.CharField(source="listing.title", read_only=True)
    neighborhood = serializers.CharField(source="listing.neighborhood", read_only=True)
    tenant_id = serializers.IntegerField(source="tenant.id", read_only=True)
    tenant_identifier = serializers.SerializerMethodField()

    class Meta:
        model = Lead
        fields = ["id", "listing_id", "listing_title", "neighborhood", "tenant_id", "tenant_identifier", "created_at", "is_read"]
        read_only_fields = fields

    def get_tenant_identifier(self, obj) -> str:
        return obj.tenant.full_name or obj.tenant.email or obj.tenant.phone_number or ""
