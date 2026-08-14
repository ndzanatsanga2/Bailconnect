from django.conf import settings
from django.utils import timezone
from datetime import timedelta

from invitations.models import Invitation
from users.services.sms import get_sms_provider

INVITATION_EXPIRY_DAYS = 14


def create_invitation(phone_number: str, *, listing=None, lead=None, created_by=None) -> Invitation:
    invitation = Invitation.objects.create(
        phone_number=phone_number,
        listing=listing,
        lead=lead,
        created_by=created_by,
        expires_at=timezone.now() + timedelta(days=INVITATION_EXPIRY_DAYS),
    )
    link = f"{settings.FRONTEND_URL}/invitations/{invitation.token}"
    get_sms_provider().send(
        phone_number,
        f"Un locataire s'intéresse à votre bien sur Bailconnect. Créez votre compte : {link}",
    )
    return invitation


def accept_invitation(token: str, *, full_name: str = "") -> "tuple[object, Invitation]":
    """Crée/récupère le compte annonceur lié au token et lui rattache l'annonce
    d'amorçage. Retourne (user, invitation). Lève Invitation.DoesNotExist si le
    token est invalide, ValueError s'il est expiré ou déjà utilisé."""
    invitation = Invitation.objects.select_related("listing").get(token=token)

    if invitation.used_at is not None:
        raise ValueError("Cette invitation a déjà été utilisée.")
    if invitation.is_expired():
        raise ValueError("Cette invitation a expiré.")

    from users.models import User

    user, _ = User.objects.get_or_create(
        phone_number=invitation.phone_number,
        defaults={"role": User.Role.ANNONCEUR, "full_name": full_name},
    )

    if invitation.listing is not None and invitation.listing.owner_id is None:
        invitation.listing.owner = user
        invitation.listing.save(update_fields=["owner"])

    invitation.used_at = timezone.now()
    invitation.save(update_fields=["used_at"])

    return user, invitation
