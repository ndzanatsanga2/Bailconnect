from django.contrib import admin

from leads.models import Lead


@admin.register(Lead)
class LeadAdmin(admin.ModelAdmin):
    list_display = ["tenant", "listing", "created_at"]
    search_fields = ["tenant__phone_number", "listing__title"]
    list_filter = ["created_at"]
