from datetime import timedelta

from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.exceptions import ValidationError
from django.core.validators import RegexValidator
from django.db import models
from django.utils import timezone

phone_validator = RegexValidator(
    regex=r"^\+?[0-9]{8,15}$",
    message="Numéro de téléphone invalide (format attendu : +237XXXXXXXXX).",
)


class UserManager(BaseUserManager):
    use_in_migrations = True

    def create_user(self, phone_number=None, email=None, role="locataire", password=None, **extra_fields):
        if not phone_number and not email:
            raise ValueError("Un numéro de téléphone ou un email est obligatoire.")
        if email:
            email = self.normalize_email(email)
        extra_fields.setdefault("is_annonceur", role == self.model.Role.ANNONCEUR)
        user = self.model(phone_number=phone_number or None, email=email or None, role=role, **extra_fields)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number=None, email=None, password=None, **extra_fields):
        extra_fields.setdefault("role", "admin")
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        if extra_fields.get("is_staff") is not True:
            raise ValueError("Un superuser doit avoir is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Un superuser doit avoir is_superuser=True.")
        return self.create_user(phone_number=phone_number, email=email, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        LOCATAIRE = "locataire", "Locataire"
        ANNONCEUR = "annonceur", "Annonceur"
        ADMIN = "admin", "Admin"

    phone_number = models.CharField(
        max_length=20, unique=True, null=True, blank=True, validators=[phone_validator],
    )
    email = models.EmailField(max_length=254, unique=True, null=True, blank=True)
    full_name = models.CharField(max_length=150, blank=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.LOCATAIRE)
    is_annonceur = models.BooleanField(
        default=False,
        help_text="Capacité de gérer des annonces — un compte locataire peut aussi l'acquérir (ex. amorçage).",
    )
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "phone_number"
    REQUIRED_FIELDS = []

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=models.Q(email__isnull=False) | models.Q(phone_number__isnull=False),
                name="user_email_or_phone_required",
            ),
        ]

    def clean(self):
        super().clean()
        if not self.email and not self.phone_number:
            raise ValidationError("Un numéro de téléphone ou un email est obligatoire.")

    def __str__(self):
        return f"{self.email or self.phone_number} ({self.role})"


class OTPCode(models.Model):
    class Channel(models.TextChoices):
        SMS = "sms", "SMS"
        EMAIL = "email", "Email"

    identifier = models.CharField(max_length=254, db_index=True, help_text="Numéro de téléphone ou email.")
    channel = models.CharField(max_length=10, choices=Channel.choices)
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
        return f"OTP {self.identifier} ({'utilisé' if self.is_used else 'actif'})"
