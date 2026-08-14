from django.conf import settings
from django.db import models

from listings.models import Listing


class Lead(models.Model):
    listing = models.ForeignKey(Listing, on_delete=models.CASCADE, related_name="leads")
    tenant = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="leads"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Lead {self.tenant} → {self.listing}"
