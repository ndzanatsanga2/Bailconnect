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

## Démarrage frontend (Flutter — PWA en priorité)

```bash
cd frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```
