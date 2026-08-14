from rest_framework.routers import DefaultRouter

from listings.views import AmenityViewSet, FavoriteViewSet, FeedViewSet, ListingViewSet

router = DefaultRouter()
router.register("listings", ListingViewSet, basename="listing")
router.register("amenities", AmenityViewSet, basename="amenity")
router.register("feed", FeedViewSet, basename="feed")
router.register("favorites", FavoriteViewSet, basename="favorite")

urlpatterns = router.urls
