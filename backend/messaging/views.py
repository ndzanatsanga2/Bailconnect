from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from listings.models import Listing
from messaging.models import Conversation
from messaging.serializers import ConversationSerializer, MessageSerializer
from users.models import User


class ConversationViewSet(viewsets.ModelViewSet):
    """Boîte de conversations de l'utilisateur connecté (client ou
    annonceur) — seuls les deux participants d'une conversation peuvent y
    accéder (get_queryset filtre déjà, get_object() 404 pour les autres)."""

    http_method_names = ["get", "post", "head", "options"]
    serializer_class = ConversationSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        return {"request": self.request}

    def get_queryset(self):
        user = self.request.user
        return (
            Conversation.objects.filter(Q(client=user) | Q(annonceur=user))
            .select_related("listing", "client", "annonceur")
        )

    def create(self, request, *args, **kwargs):
        listing = get_object_or_404(Listing, pk=request.data.get("listing_id"))
        user = request.user

        if listing.owner_id == user.id:
            peer_id = request.data.get("peer_id")
            if not peer_id:
                return Response({"detail": "peer_id est requis pour démarrer une conversation en tant qu'annonceur."}, status=400)
            client = get_object_or_404(User, pk=peer_id)
            annonceur = user
        else:
            if listing.owner_id is None:
                return Response({"detail": "Cette annonce n'a pas encore d'annonceur inscrit."}, status=400)
            client = user
            annonceur = listing.owner

        conversation, _ = Conversation.objects.get_or_create(listing=listing, client=client, annonceur=annonceur)
        return Response(self.get_serializer(conversation).data, status=201)

    @action(detail=True, methods=["get", "post"])
    def messages(self, request, pk=None):
        conversation = self.get_object()

        if request.method == "GET":
            qs = conversation.messages.select_related("author").order_by("created_at")
            return Response(MessageSerializer(qs, many=True, context={"request": request}).data)

        serializer = MessageSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        message = conversation.messages.create(author=request.user, text=serializer.validated_data["text"])
        conversation.save()  # bump updated_at (auto_now) pour le tri par activité récente
        return Response(MessageSerializer(message, context={"request": request}).data, status=201)

    @action(detail=True, methods=["post"], url_path="mark-read")
    def mark_read(self, request, pk=None):
        conversation = self.get_object()
        conversation.messages.exclude(author=request.user).update(is_read=True)
        return Response({"detail": "ok"})
