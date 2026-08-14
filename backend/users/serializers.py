import re

from rest_framework import serializers

from users.models import User


def normalize_phone_number(value: str) -> str:
    """Retire espaces/tirets éventuels ; conserve le préfixe international."""
    value = value.strip()
    prefix = "+" if value.startswith("+") else ""
    return prefix + re.sub(r"\D", "", value)


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "phone_number", "email", "full_name", "role", "date_joined"]
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


class OTPVerifySerializer(IdentifierMixin):
    code = serializers.CharField()
    role = serializers.ChoiceField(
        choices=[User.Role.LOCATAIRE, User.Role.ANNONCEUR], required=False
    )
    full_name = serializers.CharField(required=False, allow_blank=True)
