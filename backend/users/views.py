from datetime import timedelta

from django.db.models import Q
from django.utils import timezone
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from users.models import User
from users.serializers import (
    BecomeAnnonceurSerializer,
    LoginSerializer,
    OTPRequestSerializer,
    PasswordResetConfirmSerializer,
    RegisterSerializer,
    UserSerializer,
)
from users.services.otp import generate_and_send_otp, verify_otp

LOGIN_MAX_ATTEMPTS = 5
LOGIN_LOCKOUT_MINUTES = 15
INVALID_CREDENTIALS_DETAIL = "Identifiant ou mot de passe incorrect."


def _find_user(data) -> User | None:
    if data.get("email"):
        return User.objects.filter(email=data["email"]).first()
    return User.objects.filter(phone_number=data["phone_number"]).first()


class RequestOTPView(APIView):
    """Envoie un code OTP — utilisé pour vérifier un compte à l'inscription
    et pour la réinitialisation du mot de passe."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OTPRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.identifier(serializer.validated_data)
        generate_and_send_otp(identifier)
        # Le code n'est jamais renvoyé dans la réponse API, seulement transmis par SMS/email.
        return Response({"detail": "Code envoyé."})


class RegisterView(APIView):
    """Inscription client ou annonceur — crée le compte (avec mot de passe)
    une fois le code OTP (envoyé par SMS au numéro fourni) vérifié."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        if not verify_otp(data["phone_number"], data["code"]):
            return Response({"detail": "Code invalide ou expiré."}, status=400)

        if User.objects.filter(Q(phone_number=data["phone_number"]) | Q(email=data["email"])).exists():
            return Response({"detail": "Un compte existe déjà avec cet email ou ce numéro."}, status=400)

        user = User.objects.create_user(
            phone_number=data["phone_number"],
            email=data["email"],
            role=data["role"],
            full_name=data["full_name"],
            password=data["password"],
            city=data.get("city", ""),
            whatsapp_number=data.get("whatsapp_number", ""),
            annonceur_type=data.get("annonceur_type", ""),
        )
        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "user": UserSerializer(user).data}, status=201)


class LoginView(APIView):
    """Connexion par mot de passe — identifiant (email ou téléphone) déjà
    enregistré. Verrouille temporairement le compte après plusieurs échecs."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        user = _find_user(data)

        if user is None:
            return Response({"detail": INVALID_CREDENTIALS_DETAIL}, status=400)

        if user.login_locked_until and user.login_locked_until > timezone.now():
            return Response(
                {"detail": "Compte temporairement bloqué suite à plusieurs tentatives. Réessayez plus tard."},
                status=423,
            )

        if not user.check_password(data["password"]):
            user.login_failed_attempts += 1
            if user.login_failed_attempts >= LOGIN_MAX_ATTEMPTS:
                user.login_locked_until = timezone.now() + timedelta(minutes=LOGIN_LOCKOUT_MINUTES)
            user.save(update_fields=["login_failed_attempts", "login_locked_until"])
            return Response({"detail": INVALID_CREDENTIALS_DETAIL}, status=400)

        if user.login_failed_attempts or user.login_locked_until:
            user.login_failed_attempts = 0
            user.login_locked_until = None
            user.save(update_fields=["login_failed_attempts", "login_locked_until"])

        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "user": UserSerializer(user).data})


class PasswordResetConfirmView(APIView):
    """Réinitialisation du mot de passe — code OTP (envoyé via
    /otp/request/) puis nouveau mot de passe. Reconnecte l'utilisateur."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        identifier = serializer.identifier(data)

        if not verify_otp(identifier, data["code"]):
            return Response({"detail": "Code invalide ou expiré."}, status=400)

        user = _find_user(data)
        if user is None:
            return Response({"detail": "Aucun compte trouvé pour cet identifiant."}, status=404)

        user.set_password(data["new_password"])
        user.login_failed_attempts = 0
        user.login_locked_until = None
        user.save()

        token, _ = Token.objects.get_or_create(user=user)
        return Response({"token": token.key, "user": UserSerializer(user).data})


class BecomeAnnonceurView(APIView):
    """Un locataire ajoute la capacité annonceur à son compte (double casquette)."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = BecomeAnnonceurSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = request.user
        user.is_annonceur = True
        user.whatsapp_number = serializer.validated_data["whatsapp_number"]
        user.annonceur_type = serializer.validated_data["annonceur_type"]
        user.save(update_fields=["is_annonceur", "whatsapp_number", "annonceur_type"])
        return Response(UserSerializer(user).data)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)
