from django.urls import path

from users.views import (
    BecomeAnnonceurView,
    LoginView,
    MeView,
    PasswordResetConfirmView,
    RegisterView,
    RequestOTPView,
)

urlpatterns = [
    path("otp/request/", RequestOTPView.as_view(), name="otp-request"),
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("password/reset/confirm/", PasswordResetConfirmView.as_view(), name="password-reset-confirm"),
    path("capacity/annonceur/", BecomeAnnonceurView.as_view(), name="become-annonceur"),
    path("me/", MeView.as_view(), name="me"),
]
