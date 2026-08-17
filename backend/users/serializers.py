import re

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from users.constants import CITY_CHOICES
from users.models import User, phone_validator


def normalize_phone_number(value: str) -> str:
    """Retire espaces/tirets éventuels ; conserve le préfixe international."""
    value = value.strip()
    prefix = "+" if value.startswith("+") else ""
    return prefix + re.sub(r"\D", "", value)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "phone_number", "email", "full_name", "role", "is_annonceur",
            "city", "whatsapp_number", "annonceur_type", "date_joined",
        ]
        read_only_fields = fields


class IdentifierMixin(serializers.Serializer):
    """Un numéro de téléphone OU un email — au moins l'un des deux."""

    phone_number = serializers.CharField(required=False, allow_blank=True, default="")
    email = serializers.EmailField(required=False, allow_blank=True, default="")

    def validate_phone_number(self, value):
        return normalize_phone_number(value) if value else ""

    def validate(self, attrs):
        if not attrs.get("phone_number") and not attrs.get("email"):
            raise serializers.ValidationError("Un numéro de téléphone ou un email est requis.")
        return attrs

    @staticmethod
    def identifier(validated_data) -> str:
        return validated_data.get("email") or validated_data.get("phone_number")


class OTPRequestSerializer(IdentifierMixin):
    pass


class PasswordFieldsMixin(serializers.Serializer):
    """Validation commune mot de passe + confirmation, réutilisée à
    l'inscription et à la réinitialisation."""

    def _validate_match(self, attrs, password_field: str, confirm_field: str):
        if attrs.get(password_field) != attrs.get(confirm_field):
            raise serializers.ValidationError({confirm_field: "Les mots de passe ne correspondent pas."})
        try:
            validate_password(attrs[password_field])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({password_field: list(exc.messages)})


class RegisterSerializer(PasswordFieldsMixin):
    """Inscription client ou annonceur — champs communs + champs propres au
    rôle choisi, vérifiés en un seul appel via le code OTP envoyé par SMS ou
    email selon otp_channel (repli si le SMS n'arrive pas). Le mot de passe
    défini ici sert ensuite aux connexions ultérieures."""

    role = serializers.ChoiceField(choices=[User.Role.LOCATAIRE, User.Role.ANNONCEUR])
    phone_number = serializers.CharField()
    email = serializers.EmailField()
    code = serializers.CharField()
    otp_channel = serializers.ChoiceField(choices=["sms", "email"], default="sms")
    full_name = serializers.CharField(allow_blank=False)
    password = serializers.CharField(write_only=True)
    password_confirm = serializers.CharField(write_only=True)
    city = serializers.CharField(required=False, allow_blank=True, default="")
    whatsapp_number = serializers.CharField(required=False, allow_blank=True, default="")
    annonceur_type = serializers.ChoiceField(choices=User.AnnonceurType.choices, required=False, allow_blank=True, default="")

    def validate_phone_number(self, value):
        return normalize_phone_number(value)

    def validate_whatsapp_number(self, value):
        if not value:
            return value
        value = normalize_phone_number(value)
        phone_validator(value)
        return value

    def validate(self, attrs):
        self._validate_match(attrs, "password", "password_confirm")
        if attrs["role"] == User.Role.LOCATAIRE:
            if attrs.get("city") not in CITY_CHOICES:
                raise serializers.ValidationError({"city": "Choisissez une ville/quartier dans la liste."})
        else:
            if not attrs.get("whatsapp_number"):
                raise serializers.ValidationError({"whatsapp_number": "Le numéro WhatsApp est requis."})
            if attrs.get("annonceur_type") not in (User.AnnonceurType.BAILLEUR, User.AnnonceurType.AGENT):
                raise serializers.ValidationError({"annonceur_type": "Choisissez bailleur ou agent."})
        return attrs


class LoginSerializer(IdentifierMixin):
    """Connexion par mot de passe — identifiant (email ou téléphone) déjà
    enregistré. Le stockage persistant du token ("Se souvenir de moi") est
    entièrement géré côté client, cet endpoint n'en a pas besoin."""

    password = serializers.CharField(write_only=True)


class PasswordResetConfirmSerializer(IdentifierMixin, PasswordFieldsMixin):
    """Réinitialisation du mot de passe — code OTP envoyé sur l'identifiant
    (via /otp/request/) puis nouveau mot de passe."""

    code = serializers.CharField()
    new_password = serializers.CharField(write_only=True)
    new_password_confirm = serializers.CharField(write_only=True)

    def validate(self, attrs):
        attrs = super().validate(attrs)
        self._validate_match(attrs, "new_password", "new_password_confirm")
        return attrs


class BecomeAnnonceurSerializer(serializers.Serializer):
    """Ajout de la capacité annonceur à un compte déjà authentifié (double casquette)."""

    whatsapp_number = serializers.CharField()
    annonceur_type = serializers.ChoiceField(choices=User.AnnonceurType.choices)

    def validate_whatsapp_number(self, value):
        value = normalize_phone_number(value)
        phone_validator(value)
        return value
