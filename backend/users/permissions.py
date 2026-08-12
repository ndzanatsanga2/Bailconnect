from rest_framework.permissions import BasePermission

from users.models import User


class IsLocataire(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.LOCATAIRE)


class IsAnnonceur(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.ANNONCEUR)


class IsAdminRole(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and request.user.role == User.Role.ADMIN)
