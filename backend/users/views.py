from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.authtoken.models import Token

from users.models import User
from users.serializers import OTPRequestSerializer, OTPVerifySerializer, UserSerializer
from users.services.otp import generate_and_send_otp, verify_otp


class RequestOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OTPRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.identifier(serializer.validated_data)
        generate_and_send_otp(identifier)
        # Le code n'est jamais renvoyé dans la réponse API, seulement transmis par SMS/email.
        return Response({"detail": "Code envoyé."})


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        identifier = serializer.identifier(data)

        if not verify_otp(identifier, data["code"]):
            return Response({"detail": "Code invalide ou expiré."}, status=400)

        role = data.get("role", User.Role.LOCATAIRE)
        defaults = {
            "role": role,
            "full_name": data.get("full_name", ""),
            "is_annonceur": role == User.Role.ANNONCEUR,
        }
        if data.get("email"):
            user, created = User.objects.get_or_create(email=data["email"], defaults=defaults)
        else:
            user, created = User.objects.get_or_create(phone_number=data["phone_number"], defaults=defaults)

        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "user": UserSerializer(user).data, "created": created})


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)
