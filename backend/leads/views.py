from django.shortcuts import get_object_or_404
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from invitations.services import create_invitation
from leads.models import Lead
from listings.models import Listing


class LeadCreateView(APIView):
    """Contact d'un bien : crée un Lead puis révèle le WhatsApp (spec point 5),
    ou déclenche l'invitation si l'annonce d'amorçage n'a pas encore d'annonceur inscrit."""

    permission_classes = [IsAuthenticated]

    def post(self, request):
        listing = get_object_or_404(
            Listing, pk=request.data.get("listing_id"), status=Listing.Status.PUBLIEE
        )
        lead = Lead.objects.create(listing=listing, tenant=request.user)

        if listing.owner_id is None:
            if listing.source == Listing.Source.AMORCE and listing.seed_contact_phone:
                create_invitation(listing.seed_contact_phone, listing=listing, lead=lead)
            return Response({"lead_id": lead.id, "whatsapp_number": None, "pending_invitation": True})

        return Response({
            "lead_id": lead.id,
            "whatsapp_number": listing.whatsapp_number,
            "pending_invitation": False,
        })
