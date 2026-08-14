from django.shortcuts import get_object_or_404
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from invitations.models import Invitation
from invitations.serializers import InvitationAcceptSerializer, InvitationDetailSerializer
from invitations.services import accept_invitation
from users.serializers import UserSerializer


class InvitationDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, token):
        invitation = get_object_or_404(Invitation, token=token)
        return Response(InvitationDetailSerializer(invitation).data)


class InvitationAcceptView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, token):
        serializer = InvitationAcceptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user, _invitation = accept_invitation(token, full_name=serializer.validated_data["full_name"])
        except Invitation.DoesNotExist:
            return Response({"detail": "Invitation introuvable."}, status=404)
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=400)

        auth_token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": auth_token.key, "user": UserSerializer(user).data})
