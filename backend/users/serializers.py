from rest_framework import serializers

from users.models import User


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "phone_number", "full_name", "role", "date_joined"]
        read_only_fields = fields


class OTPRequestSerializer(serializers.Serializer):
    phone_number = serializers.CharField()


class OTPVerifySerializer(serializers.Serializer):
    phone_number = serializers.CharField()
    code = serializers.CharField()
    role = serializers.ChoiceField(
        choices=[User.Role.LOCATAIRE, User.Role.ANNONCEUR], required=False
    )
    full_name = serializers.CharField(required=False, allow_blank=True)
