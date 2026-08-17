# Bailconnect

Plateforme camerounaise de mise en relation logement (pilote Yaoundé). Voir le
dossier de conception produit pour le contexte complet.

## Démarrage backend (Django + DRF + PostgreSQL)

```bash
cd backend
python -m venv venv
venv/Scripts/activate  # ou source venv/bin/activate sur macOS/Linux
pip install -r requirements.txt
cp .env.example .env   # puis renseigner les valeurs locales
python manage.py migrate
python manage.py runserver
```

**Base de données locale (dev)** : rôle `bailconnect` / base `bailconnect` sur
PostgreSQL, identifiants dans `backend/.env` (non versionné).

**Superuser Django Admin (dev uniquement)** :
- Téléphone : `+237600000000`
- Mot de passe : `admin-dev-2026`

Accès : `http://localhost:8000/admin/`. À ne jamais utiliser en production —
recréer un superuser dédié avec un mot de passe fort avant tout déploiement.

## Tâche planifiée : fraîcheur des annonces

Les annonces publiées sans confirmation de disponibilité depuis
`LISTING_EXPIRY_DAYS` jours (7 par défaut) doivent être expirées
automatiquement. Aucune infra de tâches planifiées (Celery, etc.) n'est dans
le stack MVP — à exécuter périodiquement via cron / Planificateur de tâches
Windows :

```bash
python manage.py expire_stale_listings
```

Exemple cron (une fois par jour) :
```
0 3 * * * cd /chemin/vers/backend && venv/bin/python manage.py expire_stale_listings
```

## OTP par email en production

Le SMS reste le canal par défaut, mais l'inscription et la réinitialisation
de mot de passe permettent d'envoyer le code par email en repli. En local,
l'envoi passe par la console (aucune config requise). En production, définir
sur Render (dashboard → service → Environment) :

| Variable | Description |
|---|---|
| `EMAIL_PROVIDER` | `smtp` (bascule l'envoi réel, sinon reste en console) |
| `EMAIL_HOST` | Hôte SMTP du service choisi |
| `EMAIL_PORT` | Port SMTP (généralement `587`) |
| `EMAIL_HOST_USER` | Identifiant SMTP |
| `EMAIL_HOST_PASSWORD` | Mot de passe / clé API SMTP |
| `EMAIL_USE_TLS` | `True` |
| `DEFAULT_FROM_EMAIL` | Expéditeur, ex. `Bailconnect <no-reply@bailconnect.cm>` |

N'importe quel service transactionnel (SendGrid, Mailgun, Resend, etc.)
convient : renseigner `EMAIL_HOST`/`EMAIL_HOST_USER`/`EMAIL_HOST_PASSWORD`
avec les identifiants de leur relais SMTP — aucune intégration API dédiée
n'est nécessaire.

## Démarrage frontend (Flutter — PWA en priorité)

```bash
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```
