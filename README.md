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

## Démarrage frontend (Flutter — PWA en priorité)

```bash
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```
