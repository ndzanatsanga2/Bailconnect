from rest_framework.permissions import BasePermission

from users.models import User


class IsLocataire(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.LOCATAIRE)


class IsAnnonceur(BasePermission):
    """Autorise tout compte ayant la capacité annonceur — un locataire peut
    aussi l'avoir (ex. amorçage accepté), sans perdre son rôle par défaut."""

    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.is_annonceur)


class IsAdminRole(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.ADMIN)
