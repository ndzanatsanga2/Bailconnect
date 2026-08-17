import os

from django.core.management.base import BaseCommand
from django.db.models import Q

from users.models import User


class Command(BaseCommand):
    """Provisionne le compte admin en environnement sans accès Shell (ex. Render free tier).

    Idempotente : sans effet si le compte existe déjà (sauf ADMIN_RESET_PASSWORD=true).
    À exécuter après les migrations, au déploiement :
        python manage.py ensure_admin
    """

    help = "Crée le compte admin depuis ADMIN_IDENTIFIER/ADMIN_PASSWORD s'il n'existe pas encore."

    def handle(self, *args, **options):
        identifier = os.environ.get("ADMIN_IDENTIFIER", "").strip()
        password = os.environ.get("ADMIN_PASSWORD", "")
        reset_password = os.environ.get("ADMIN_RESET_PASSWORD", "").lower() == "true"

        if not identifier or not password:
            self.stdout.write("ADMIN_IDENTIFIER/ADMIN_PASSWORD non définis — admin non provisionné.")
            return

        is_email = "@" in identifier
        if is_email:
            identifier = User.objects.normalize_email(identifier)
            lookup = Q(email=identifier)
        else:
            lookup = Q(phone_number=identifier)

        user = User.objects.filter(lookup).first()

        if user is not None:
            if reset_password:
                user.set_password(password)
                user.save(update_fields=["password"])
                self.stdout.write(self.style.SUCCESS(f"Mot de passe admin réinitialisé pour {identifier}."))
            else:
                self.stdout.write(f"Compte admin {identifier} déjà existant — aucune action.")
            return

        # Création directe (sans passer par create_superuser) pour éviter tout
        # conflit entre le paramètre `role` de UserManager.create_user et celui
        # injecté via extra_fields par create_superuser.
        user = User(
            email=identifier if is_email else None,
            phone_number=None if is_email else identifier,
            role=User.Role.ADMIN,
            is_staff=True,
            is_superuser=True,
            is_active=True,
        )
        user.set_password(password)
        user.full_clean(exclude=["password"])
        user.save()
        self.stdout.write(self.style.SUCCESS(f"Compte admin {identifier} créé."))
