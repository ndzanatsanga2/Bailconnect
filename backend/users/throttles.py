from rest_framework.throttling import SimpleRateThrottle


class OTPRequestThrottle(SimpleRateThrottle):
    """Limite les demandes d'OTP par identifiant (email ou téléphone) —
    empêche le spam de SMS/email vers une même cible. Repli sur l'IP si
    aucun identifiant exploitable n'est fourni (ex. payload vide)."""

    scope = "otp_request"

    def get_cache_key(self, request, view):
        identifier = (
            request.data.get("email") or request.data.get("phone_number") or ""
        ).strip().lower()
        ident = identifier or self.get_ident(request)
        return self.cache_format % {"scope": self.scope, "ident": ident}
