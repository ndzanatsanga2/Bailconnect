"""
Django settings for config project.
"""

from pathlib import Path

import environ

BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
)
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env("DJANGO_DEBUG")
ALLOWED_HOSTS = env.list("DJANGO_ALLOWED_HOSTS", default=[])

# Render fournit le hostname externe de l'app via cette variable d'env, non
# connu à l'avance (sous-domaine généré) — on l'ajoute automatiquement pour
# éviter un DisallowedHost, tout en gardant DJANGO_ALLOWED_HOSTS ci-dessus
# pour surcharger/ajouter d'autres domaines (ex. domaine custom).
RENDER_EXTERNAL_HOSTNAME = env("RENDER_EXTERNAL_HOSTNAME", default="")
if RENDER_EXTERNAL_HOSTNAME and RENDER_EXTERNAL_HOSTNAME not in ALLOWED_HOSTS:
    ALLOWED_HOSTS.append(RENDER_EXTERNAL_HOSTNAME)

# Django Admin : outil de debug interne uniquement (voir config/urls.py) — le
# back-office produit est la section admin de l'app Flutter. Coupé par défaut
# hors DEBUG ; réactivable explicitement pour du debug ponctuel en prod via
# DJANGO_ADMIN_ENABLED=True, avec un chemin non public via DJANGO_ADMIN_URL.
ADMIN_ENABLED = env.bool("DJANGO_ADMIN_ENABLED", default=DEBUG)
ADMIN_URL_PATH = env("DJANGO_ADMIN_URL", default="admin/")


# Application definition

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",

    "users",
    "listings",
    "leads",
    "invitations",
    "reports",
    "adminapi",
    "messaging",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"


# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases
#
# Render/Railway fournissent une seule variable DATABASE_URL (Postgres
# managé) ; le développement local garde les variables séparées existantes.

if env("DATABASE_URL", default=""):
    DATABASES = {"default": env.db("DATABASE_URL")}
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": env("DB_NAME"),
            "USER": env("DB_USER"),
            "PASSWORD": env("DB_PASSWORD"),
            "HOST": env("DB_HOST", default="localhost"),
            "PORT": env("DB_PORT", default="5432"),
        }
    }


AUTH_USER_MODEL = "users.User"


# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator"},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]


# Internationalization
# https://docs.djangoproject.com/en/5.2/topics/i18n/

LANGUAGE_CODE = "fr-fr"
TIME_ZONE = "Africa/Douala"
USE_I18N = True
USE_TZ = True


# Static & media files
#
# Statics servis directement par l'app via WhiteNoise (pas de webserver
# séparé nécessaire sur Render/Railway) — voir STORAGES plus bas, défini
# une fois le choix du stockage média (local/S3) connu.

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"]

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


# CORS
#
# Frontend Vercel : domaine de prod en dur ci-dessous, CORS_ALLOWED_ORIGINS
# permet d'en ajouter d'autres (liste séparée par des virgules) sans toucher
# au code. Les déploiements de preview Vercel (sous-domaines générés par
# commit/branche) passent par CORS_ALLOWED_ORIGIN_REGEXES plutôt que par une
# liste figée — c'est le nom de setting réel de django-cors-headers (au
# pluriel, liste de patterns), CORS_ALLOWED_ORIGIN_REGEX (singulier) n'existe
# pas et serait silencieusement ignoré.

CORS_ALLOWED_ORIGINS = ["https://bailconnect.vercel.app"]
CORS_ALLOWED_ORIGINS += [
    origin for origin in env.list("CORS_ALLOWED_ORIGINS", default=[])
    if origin not in CORS_ALLOWED_ORIGINS
]

CORS_ALLOWED_ORIGIN_REGEXES = [
    env("CORS_ALLOWED_ORIGIN_REGEX", default=r"^https://bailconnect-.*\.vercel\.app$")
]


# Django REST Framework

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    # otp_request : voir users/throttles.py (limite les spams de SMS/email).
    "DEFAULT_THROTTLE_RATES": {
        "otp_request": "5/hour",
    },
}


# SMS / OTP (interface abstraite — voir users/services/sms.py)

SMS_PROVIDER = env("SMS_PROVIDER", default="console")
TWILIO_ACCOUNT_SID = env("TWILIO_ACCOUNT_SID", default="")
TWILIO_AUTH_TOKEN = env("TWILIO_AUTH_TOKEN", default="")
TWILIO_FROM_NUMBER = env("TWILIO_FROM_NUMBER", default="")

OTP_CODE_LENGTH = env.int("OTP_CODE_LENGTH", default=6)
OTP_EXPIRY_MINUTES = env.int("OTP_EXPIRY_MINUTES", default=5)
OTP_MAX_ATTEMPTS = env.int("OTP_MAX_ATTEMPTS", default=5)

# Email / OTP (interface abstraite — voir users/services/email.py)
# EMAIL_PROVIDER: console (dev) ou smtp (prod) — s'appuie sur l'abstraction
# EMAIL_BACKEND déjà fournie par Django.
EMAIL_PROVIDER = env("EMAIL_PROVIDER", default="console")
DEFAULT_FROM_EMAIL = env("DEFAULT_FROM_EMAIL", default="Bailconnect <no-reply@bailconnect.cm>")

if EMAIL_PROVIDER == "smtp":
    EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
    EMAIL_HOST = env("EMAIL_HOST", default="")
    EMAIL_PORT = env.int("EMAIL_PORT", default=587)
    EMAIL_HOST_USER = env("EMAIL_HOST_USER", default="")
    EMAIL_HOST_PASSWORD = env("EMAIL_HOST_PASSWORD", default="")
    EMAIL_USE_TLS = env.bool("EMAIL_USE_TLS", default=True)
else:
    EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Fraîcheur des annonces : jours sans confirmation avant expiration auto (7-10 j)
LISTING_EXPIRY_DAYS = env.int("LISTING_EXPIRY_DAYS", default=7)


# Stockage média (interface abstraite : local en dev, S3-compatible en prod)

STORAGE_BACKEND = env("STORAGE_BACKEND", default="local")

STORAGES = {
    # WhiteNoise sert les statics (admin Django, CSS de marque) directement
    # depuis l'app, sans webserver séparé — vaut pour local/S3 également.
    "staticfiles": {"BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage"},
}

if STORAGE_BACKEND == "s3":
    STORAGES["default"] = {"BACKEND": "storages.backends.s3.S3Storage"}
    AWS_ACCESS_KEY_ID = env("AWS_ACCESS_KEY_ID", default="")
    AWS_SECRET_ACCESS_KEY = env("AWS_SECRET_ACCESS_KEY", default="")
    AWS_STORAGE_BUCKET_NAME = env("AWS_STORAGE_BUCKET_NAME", default="")
    AWS_S3_ENDPOINT_URL = env("AWS_S3_ENDPOINT_URL", default="")
    AWS_S3_REGION_NAME = env("AWS_S3_REGION_NAME", default="")
    AWS_S3_FILE_OVERWRITE = False
    AWS_DEFAULT_ACL = None
else:
    STORAGES["default"] = {"BACKEND": "django.core.files.storage.FileSystemStorage"}
    MEDIA_URL = "media/"
    MEDIA_ROOT = BASE_DIR / "media"


# Divers

FRONTEND_URL = env("FRONTEND_URL", default="http://localhost:5000")


# Sécurité HTTPS — actif uniquement hors DEBUG (Render/Railway terminent le
# TLS sur un proxy en amont et transmettent en HTTP interne, d'où le header
# X-Forwarded-Proto pour que Django sache que la requête d'origine est HTTPS).
if not DEBUG:
    SECURE_SSL_REDIRECT = True
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 60 * 60 * 24 * 7
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True

CSRF_TRUSTED_ORIGINS = env.list("CSRF_TRUSTED_ORIGINS", default=[])
if RENDER_EXTERNAL_HOSTNAME:
    render_origin = f"https://{RENDER_EXTERNAL_HOSTNAME}"
    if render_origin not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(render_origin)
for origin in CORS_ALLOWED_ORIGINS:
    if origin not in CSRF_TRUSTED_ORIGINS:
        CSRF_TRUSTED_ORIGINS.append(origin)
