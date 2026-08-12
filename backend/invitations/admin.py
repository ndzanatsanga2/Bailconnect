from django.contrib import admin

from invitations.models import Invitation


@admin.register(Invitation)
class InvitationAdmin(admin.ModelAdmin):
    list_display = ["phone_number", "listing", "created_at", "expires_at", "used_at"]
    list_filter = ["used_at"]
    search_fields = ["phone_number"]
    readonly_fields = ["token", "created_at"]
