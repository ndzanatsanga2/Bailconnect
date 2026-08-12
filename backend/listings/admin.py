from django.contrib import admin

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
    actions = ["approuver", "rejeter"]

    @admin.action(description="Approuver les annonces sélectionnées")
    def approuver(self, request, queryset):
        queryset.update(status=Listing.Status.PUBLIEE)

    @admin.action(description="Rejeter les annonces sélectionnées")
    def rejeter(self, request, queryset):
        queryset.update(status=Listing.Status.REJETEE)


@admin.register(Amenity)
class AmenityAdmin(admin.ModelAdmin):
    list_display = ["name", "icon"]
    search_fields = ["name"]


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ["user", "listing", "created_at"]
    search_fields = ["user__phone_number", "listing__title"]
