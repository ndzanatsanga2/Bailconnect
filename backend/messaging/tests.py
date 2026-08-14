import pytest
from rest_framework.test import APIClient

from listings.models import Listing
from messaging.models import Conversation, Message
from users.models import User

pytestmark = pytest.mark.django_db


def make_annonceur(phone="+237600000700"):
    return User.objects.create_user(phone_number=phone, role=User.Role.ANNONCEUR, is_annonceur=True)


def make_locataire(phone="+237600000701"):
    return User.objects.create_user(phone_number=phone, role=User.Role.LOCATAIRE)


def make_listing(owner=None, **overrides):
    defaults = dict(
        title="Studio meublé",
        neighborhood="Bastos",
        property_type=Listing.PropertyType.STUDIO,
        rent_amount=75000,
        whatsapp_number="+237600000800",
        status=Listing.Status.PUBLIEE,
    )
    defaults.update(overrides)
    return Listing.objects.create(owner=owner, **defaults)


class TestConversationCreation:
    def test_client_can_start_conversation_with_listing_owner(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        client_user = make_locataire()
        client = APIClient()
        client.force_authenticate(client_user)

        response = client.post("/api/messaging/conversations/", {"listing_id": listing.id})

        assert response.status_code == 201
        assert response.data["peer_id"] == annonceur.id
        assert Conversation.objects.filter(listing=listing, client=client_user, annonceur=annonceur).exists()

    def test_annonceur_can_start_conversation_with_a_client_via_peer_id(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        client = APIClient()
        client.force_authenticate(annonceur)

        response = client.post("/api/messaging/conversations/", {"listing_id": listing.id, "peer_id": tenant.id})

        assert response.status_code == 201
        assert response.data["peer_id"] == tenant.id

    def test_annonceur_without_peer_id_gets_clean_error(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        client = APIClient()
        client.force_authenticate(annonceur)

        response = client.post("/api/messaging/conversations/", {"listing_id": listing.id})

        assert response.status_code == 400

    def test_starting_conversation_twice_is_idempotent(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        client = APIClient()
        client.force_authenticate(tenant)

        first = client.post("/api/messaging/conversations/", {"listing_id": listing.id})
        second = client.post("/api/messaging/conversations/", {"listing_id": listing.id})

        assert first.data["id"] == second.data["id"]
        assert Conversation.objects.count() == 1


class TestConversationList:
    def test_conversation_appears_for_both_participants(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)

        tenant_client = APIClient()
        tenant_client.force_authenticate(tenant)
        annonceur_client = APIClient()
        annonceur_client.force_authenticate(annonceur)

        assert [c["id"] for c in tenant_client.get("/api/messaging/conversations/").data] == [conversation.id]
        assert [c["id"] for c in annonceur_client.get("/api/messaging/conversations/").data] == [conversation.id]

    def test_conversation_does_not_appear_for_unrelated_user(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)
        other = make_locataire("+237600000702")

        client = APIClient()
        client.force_authenticate(other)

        assert client.get("/api/messaging/conversations/").data == []


class TestMessages:
    def test_participant_can_post_and_list_messages(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)

        client = APIClient()
        client.force_authenticate(tenant)

        post_response = client.post(f"/api/messaging/conversations/{conversation.id}/messages/", {"text": "Bonjour, le bien est-il toujours disponible ?"})
        assert post_response.status_code == 201
        assert post_response.data["is_mine"] is True

        list_response = client.get(f"/api/messaging/conversations/{conversation.id}/messages/")
        assert len(list_response.data) == 1
        assert list_response.data[0]["text"] == "Bonjour, le bien est-il toujours disponible ?"

    def test_non_participant_cannot_access_messages(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)
        other = make_locataire("+237600000703")

        client = APIClient()
        client.force_authenticate(other)

        response = client.get(f"/api/messaging/conversations/{conversation.id}/messages/")
        assert response.status_code == 404

    def test_empty_message_is_rejected(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)

        client = APIClient()
        client.force_authenticate(tenant)

        response = client.post(f"/api/messaging/conversations/{conversation.id}/messages/", {"text": "   "})
        assert response.status_code == 400

    def test_posting_message_bumps_conversation_updated_at_for_ordering(self):
        annonceur = make_annonceur()
        listing_a = make_listing(owner=annonceur, title="Bien A")
        listing_b = make_listing(owner=annonceur, title="Bien B")
        tenant = make_locataire()
        older = Conversation.objects.create(listing=listing_a, client=tenant, annonceur=annonceur)
        newer = Conversation.objects.create(listing=listing_b, client=tenant, annonceur=annonceur)

        client = APIClient()
        client.force_authenticate(tenant)
        client.post(f"/api/messaging/conversations/{older.id}/messages/", {"text": "Toujours dispo ?"})

        response = client.get("/api/messaging/conversations/")
        assert response.data[0]["id"] == older.id


class TestUnreadAndMarkRead:
    def test_unread_count_excludes_own_messages(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)
        Message.objects.create(conversation=conversation, author=tenant, text="Salut")
        Message.objects.create(conversation=conversation, author=annonceur, text="Bonjour")

        tenant_client = APIClient()
        tenant_client.force_authenticate(tenant)
        response = tenant_client.get("/api/messaging/conversations/")

        assert response.data[0]["unread_count"] == 1

    def test_mark_read_clears_unread_count_for_reader(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)
        Message.objects.create(conversation=conversation, author=annonceur, text="Bonjour")

        tenant_client = APIClient()
        tenant_client.force_authenticate(tenant)
        tenant_client.post(f"/api/messaging/conversations/{conversation.id}/mark-read/")

        response = tenant_client.get("/api/messaging/conversations/")
        assert response.data[0]["unread_count"] == 0

    def test_non_participant_cannot_mark_read(self):
        annonceur = make_annonceur()
        listing = make_listing(owner=annonceur)
        tenant = make_locataire()
        conversation = Conversation.objects.create(listing=listing, client=tenant, annonceur=annonceur)
        other = make_locataire("+237600000704")

        client = APIClient()
        client.force_authenticate(other)

        response = client.post(f"/api/messaging/conversations/{conversation.id}/mark-read/")
        assert response.status_code == 404
