from rest_framework.throttling import SimpleRateThrottle


class _IdentifierThrottle(SimpleRateThrottle):
    """Base commune : throttle par identifiant (email ou téléphone soumis
    dans le payload), avec repli sur l'IP si aucun des deux n'est
    exploitable (ex. payload vide). Une sous-classe par endpoint sensible
    fournit son propre `scope` pour ne pas partager le même compteur."""

    def get_cache_key(self, request, view):
        identifier = (
            request.data.get("email") or request.data.get("phone_number") or ""
        ).strip().lower()
        ident = identifier or self.get_ident(request)
        return self.cache_format % {"scope": self.scope, "ident": ident}


class OTPRequestThrottle(_IdentifierThrottle):
    """Limite les demandes d'OTP par identifiant (email ou téléphone) —
    empêche le spam de SMS/email vers une même cible."""

    scope = "otp_request"


class LoginThrottle(_IdentifierThrottle):
    """Limite les tentatives de connexion par identifiant — freine le
    brute-force par mot de passe en complément du verrouillage de compte
    après échecs répétés (voir LOGIN_MAX_ATTEMPTS dans users/views.py)."""

    scope = "login"


class RegisterThrottle(_IdentifierThrottle):
    """Limite les inscriptions par identifiant (email ou téléphone soumis)
    — freine la création automatisée de comptes, en particulier quand
    OTP_REQUIRED=false ne protège plus ce endpoint."""

    scope = "register"


class PasswordResetThrottle(_IdentifierThrottle):
    """Limite les tentatives de réinitialisation de mot de passe par
    identifiant — freine le brute-force du code OTP de réinitialisation."""

    scope = "password_reset"
