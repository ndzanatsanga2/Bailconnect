from django.contrib import admin

from reports.models import Report


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ["listing", "reporter", "reason", "status", "created_at"]
    list_filter = ["status", "reason"]
    search_fields = ["listing__title", "reporter__phone_number"]
    actions = ["marquer_traite", "marquer_rejete"]

    @admin.action(description="Marquer comme traité")
    def marquer_traite(self, request, queryset):
        queryset.update(status=Report.Status.TRAITE)

    @admin.action(description="Marquer comme rejeté")
    def marquer_rejete(self, request, queryset):
        queryset.update(status=Report.Status.REJETE)
