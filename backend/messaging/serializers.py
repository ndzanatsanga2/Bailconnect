from rest_framework import serializers

from messaging.models import Conversation, Message


class ConversationSerializer(serializers.ModelSerializer):
    """Vue « boîte de conversations » — nom du correspondant et aperçu
    calculés du point de vue de l'utilisateur connecté (request en contexte)."""

    listing_id = serializers.IntegerField(source="listing.id", read_only=True)
    listing_title = serializers.CharField(source="listing.title", read_only=True)
    peer_id = serializers.SerializerMethodField()
    peer_name = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = [
            "id", "listing_id", "listing_title", "peer_id", "peer_name",
            "last_message", "unread_count", "updated_at",
        ]
        read_only_fields = fields

    def _peer(self, obj):
        request = self.context.get("request")
        user = getattr(request, "user", None)
        return obj.annonceur if user and user.id == obj.client_id else obj.client

    def get_peer_id(self, obj) -> int:
        return self._peer(obj).id

    def get_peer_name(self, obj) -> str:
        peer = self._peer(obj)
        return peer.full_name or peer.email or peer.phone_number or ""

    def get_last_message(self, obj) -> str | None:
        last = obj.messages.order_by("-created_at").first()
        return last.text if last else None

    def get_unread_count(self, obj) -> int:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None:
            return 0
        return obj.messages.filter(is_read=False).exclude(author=user).count()


class MessageSerializer(serializers.ModelSerializer):
    author_id = serializers.IntegerField(source="author.id", read_only=True)
    is_mine = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ["id", "author_id", "is_mine", "text", "created_at", "is_read"]
        read_only_fields = ["id", "author_id", "is_mine", "created_at", "is_read"]

    def get_is_mine(self, obj) -> bool:
        request = self.context.get("request")
        user = getattr(request, "user", None)
        return bool(user and obj.author_id == user.id)

    def validate_text(self, value: str) -> str:
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Le message ne peut pas être vide.")
        return value
