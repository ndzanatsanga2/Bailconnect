from datetime import timedelta

import pytest
from django.utils import timezone
from rest_framework.test import APIClient

from invitations.models import Invitation
from invitations.services import accept_invitation, create_invitation
from listings.models import Listing
from users.models import User

pytestmark = pytest.mark.django_db


def make_amorce_listing():
    return Listing.objects.create(
        owner=None,
        title="Studio meublé (amorçage)",
        neighborhood="Bastos",
        property_type=Listing.PropertyType.STUDIO,
        rent_amount=75000,
        whatsapp_number="+237600000300",
        status=Listing.Status.PUBLIEE,
        source=Listing.Source.AMORCE,
        seed_contact_name="M. Ateba",
        seed_contact_phone="+237600000301",
    )


class TestCreateInvitation:
    def test_creates_invitation_and_sends_link(self):
        listing = make_amorce_listing()
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)

        assert invitation.phone_number == listing.seed_contact_phone
        assert invitation.listing == listing
        assert invitation.used_at is None
        assert not invitation.is_expired()


class TestAcceptInvitation:
    def test_accept_creates_annonceur_and_attaches_listing(self):
        listing = make_amorce_listing()
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)

        user, updated_invitation = accept_invitation(str(invitation.token), full_name="M. Ateba")

        assert user.role == User.Role.ANNONCEUR
        assert user.is_annonceur is True
        assert user.phone_number == listing.seed_contact_phone
        listing.refresh_from_db()
        assert listing.owner == user
        assert updated_invitation.used_at is not None

    def test_accept_by_existing_locataire_grants_annonceur_capacity_without_changing_role(self):
        listing = make_amorce_listing()
        locataire = User.objects.create_user(phone_number=listing.seed_contact_phone, role=User.Role.LOCATAIRE)
        assert locataire.is_annonceur is False
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)

        user, _ = accept_invitation(str(invitation.token))

        assert user.id == locataire.id
        assert user.role == User.Role.LOCATAIRE
        assert user.is_annonceur is True
        listing.refresh_from_db()
        assert listing.owner == user

    def test_locataire_with_annonceur_capacity_can_manage_attached_listing(self):
        listing = make_amorce_listing()
        User.objects.create_user(phone_number=listing.seed_contact_phone, role=User.Role.LOCATAIRE)
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)
        user, _ = accept_invitation(str(invitation.token))

        client = APIClient()
        client.force_authenticate(user=user)
        response = client.patch(f"/api/listings/{listing.id}/", {"title": "Studio rénové"})

        assert response.status_code == 200
        listing.refresh_from_db()
        assert listing.title == "Studio rénové"

    def test_accept_twice_fails(self):
        listing = make_amorce_listing()
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)
        accept_invitation(str(invitation.token))

        with pytest.raises(ValueError):
            accept_invitation(str(invitation.token))

    def test_accept_expired_fails(self):
        listing = make_amorce_listing()
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)
        invitation.expires_at = timezone.now() - timedelta(days=1)
        invitation.save(update_fields=["expires_at"])

        with pytest.raises(ValueError):
            accept_invitation(str(invitation.token))

    def test_accept_unknown_token_raises_does_not_exist(self):
        with pytest.raises(Invitation.DoesNotExist):
            accept_invitation("00000000-0000-0000-0000-000000000000")


class TestInvitationEndpoints:
    def test_detail_endpoint_is_public(self):
        listing = make_amorce_listing()
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)
        client = APIClient()

        response = client.get(f"/api/invitations/{invitation.token}/")

        assert response.status_code == 200
        assert response.data["listing_title"] == listing.title
        assert response.data["is_used"] is False

    def test_accept_endpoint_returns_token(self):
        listing = make_amorce_listing()
        invitation = create_invitation(listing.seed_contact_phone, listing=listing)
        client = APIClient()

        response = client.post(f"/api/invitations/{invitation.token}/accept/", {"full_name": "M. Ateba"})

        assert response.status_code == 200
        assert response.data["token"]
        assert response.data["user"]["role"] == User.Role.ANNONCEUR

    def test_accept_endpoint_with_unknown_token_returns_404(self):
        client = APIClient()
        response = client.post("/api/invitations/00000000-0000-0000-0000-000000000000/accept/", {})
        assert response.status_code == 404
