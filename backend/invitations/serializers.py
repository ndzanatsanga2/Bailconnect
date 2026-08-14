from rest_framework import serializers

from invitations.models import Invitation


class InvitationDetailSerializer(serializers.Serializer):
    listing_title = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()
    is_used = serializers.SerializerMethodField()

    def get_listing_title(self, obj: Invitation):
        return obj.listing.title if obj.listing else None

    def get_is_expired(self, obj: Invitation):
        return obj.is_expired()

    def get_is_used(self, obj: Invitation):
        return obj.used_at is not None


class InvitationAcceptSerializer(serializers.Serializer):
    full_name = serializers.CharField(required=False, allow_blank=True, default="")
