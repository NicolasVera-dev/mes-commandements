#!/usr/bin/env bash
# Supprime lib/firebase_options.dart et android/app/google-services.json
# de TOUT l'historique Git (y compris les clés qui y figuraient).
#
# Prérequis : pip install git-filter-repo
#   (ou brew install git-filter-repo)
#
# Après exécution :
#   - Réassocier le remote : git remote add origin <url>
#   - Pousser en forçant : git push --force --all
#   - Demander aux contributeurs de recloner ou de reset dur
#   - Régénérer / restreindre les clés API Firebase (Console Google Cloud)
#
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "Installez git-filter-repo : pip install git-filter-repo"
  exit 1
fi

git filter-repo \
  --path lib/firebase_options.dart \
  --path android/app/google-services.json \
  --invert-paths \
  --force

echo "Historique réécrit. Vérifiez avec : git log --all -- lib/firebase_options.dart"
