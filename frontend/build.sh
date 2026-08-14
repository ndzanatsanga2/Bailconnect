#!/usr/bin/env bash
# Build de production pour Vercel — Flutter n'est pas un framework reconnu
# nativement, donc ce script installe le SDK à la volée dans le conteneur de
# build (éphémère, refait à chaque déploiement) avant de builder le web.
set -euo pipefail

FLUTTER_REF="3.44.7"

if [ -z "${API_BASE_URL:-}" ]; then
  echo "Erreur : la variable d'environnement API_BASE_URL doit être définie (URL publique du backend, jamais localhost)." >&2
  exit 1
fi

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_REF" --depth 1
fi
export PATH="$PATH:$(pwd)/flutter/bin"

flutter config --enable-web --no-analytics
flutter pub get
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL" --base-href /
