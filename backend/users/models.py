from datetime import timedelta

from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

phone_validator = RegexValidator(
    regex=r"^\+?[0-9]{8,15}$",
    message="Numéro de téléphone invalide (format attendu : +237XXXXXXXXX).",
)


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, phone_number, role="locataire", password=None, **extra_fields):
        if not phone_number:
            raise ValueError("Le numéro de téléphone est obligatoire.")
        user = self.model(phone_number=phone_number, role=role, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault("role", "admin")
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Un superuser doit avoir is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Un superuser doit avoir is_superuser=True.")
        return self.create_user(phone_number, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        LOCATAIRE = "locataire", "Locataire"
        ANNONCEUR = "annonceur", "Annonceur"
        ADMIN = "admin", "Admin"

    phone_number = models.CharField(
        max_length=20, unique=True, validators=[phone_validator]
    )
    full_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.LOCATAIRE)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = []

    def __str__(self):
        return f"{self.phone_number} ({self.role})"


class OTPCode(models.Model):
    phone_number = models.CharField(max_length=20, db_index=True, validators=[phone_validator])
    code_hash = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    attempts = models.PositiveSmallIntegerField(default=0)

    class Meta:
        ordering = ["-created_at"]

    def set_code(self, raw_code: str):
        self.code_hash = make_password(raw_code)

    def check_code(self, raw_code: str) -> bool:
        return check_password(raw_code, self.code_hash)

    def is_expired(self) -> bool:
        return timezone.now() > self.expires_at

    @classmethod
    def new_expiry(cls, minutes: int):
        return timezone.now() + timedelta(minutes=minutes)

    def __str__(self):
        return f"OTP {self.phone_number} ({'utilisé' if self.is_used else 'actif'})"
