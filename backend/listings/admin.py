from django.contrib import admin, messages

from invitations.services import create_invitation
from listings.models import Amenity, Favorite, Listing, ListingMedia


class ListingMediaInline(admin.TabularInline):
    model = ListingMedia
    extra = 0


@admin.register(Listing)
class ListingAdmin(admin.ModelAdmin):
    list_display = [
        "title", "owner", "neighborhood", "property_type", "rent_amount",
        "status", "source", "verified", "created_at",
    ]
    list_filter = ["status", "source", "property_type", "verified", "neighborhood"]
    search_fields = ["title", "neighborhood", "owner__phone_number"]
    inlines = [ListingMediaInline]
    actions = ["approuver", "rejeter", "envoyer_invitation"]

    @admin.action(description="Approuver les annonces sélectionnées")
    def approuver(self, request, queryset):
        queryset.update(status=Listing.Status.PUBLIEE)

    @admin.action(description="Rejeter les annonces sélectionnées")
    def rejeter(self, request, queryset):
        queryset.update(status=Listing.Status.REJETEE)

    @admin.action(description="Envoyer l'invitation à l'annonceur (amorçage)")
    def envoyer_invitation(self, request, queryset):
        sent = 0
        for listing in queryset:
            if listing.source != Listing.Source.AMORCE or listing.owner_id is not None:
                continue
            if not listing.seed_contact_phone:
                self.message_user(
                    request,
                    f"« {listing.title} » n'a pas de numéro de contact d'amorçage renseigné.",
                    level=messages.WARNING,
                )
                continue
            create_invitation(listing.seed_contact_phone, listing=listing, created_by=request.user)
            sent += 1
        if sent:
            self.message_user(request, f"{sent} invitation(s) envoyée(s).", level=messages.SUCCESS)


@admin.register(Amenity)
class AmenityAdmin(admin.ModelAdmin):
    list_display = ["name", "icon"]
    search_fields = ["name"]


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ["user", "listing", "created_at"]
    search_fields = ["user__phone_number", "listing__title"]
