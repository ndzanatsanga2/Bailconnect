from django.contrib import admin

from messaging.models import Conversation, Message


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ["id", "listing", "client", "annonceur", "updated_at"]
    search_fields = ["listing__title", "client__email", "annonceur__email"]


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ["id", "conversation", "author", "created_at", "is_read"]
