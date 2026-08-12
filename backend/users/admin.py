from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from users.models import OTPCode, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    model = User
    ordering = ["-date_joined"]
    list_display = ["phone_number", "full_name", "role", "is_active", "is_staff", "date_joined"]
    list_filter = ["role", "is_active", "is_staff"]
    search_fields = ["phone_number", "full_name"]
    fieldsets = (
        (None, {"fields": ("phone_number", "password")}),
        ("Informations", {"fields": ("full_name", "role")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Dates", {"fields": ("date_joined", "last_login")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("phone_number", "role", "password1", "password2")}),
    )
    readonly_fields = ["date_joined", "last_login"]


@admin.register(OTPCode)
class OTPCodeAdmin(admin.ModelAdmin):
    list_display = ["phone_number", "created_at", "expires_at", "is_used", "attempts"]
    list_filter = ["is_used"]
    search_fields = ["phone_number"]
    readonly_fields = ["code_hash", "created_at"]
