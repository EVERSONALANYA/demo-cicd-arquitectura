#!/usr/bin/env bash
# Escenario 1 (camino feliz): cambia la versión de la app y abre un pull request.
# Uso: bash scripts/cambiar-version.sh 1.2.0
set -euo pipefail

NUEVA="${1:?Indica la versión nueva, por ejemplo: bash scripts/cambiar-version.sh 1.2.0}"
RAMA="version-${NUEVA//./-}"

git checkout main
git pull --ff-only
git checkout -b "$RAMA"

# Cambia el campo "version" de package.json (no necesita npm)
sed -i -E "s/\"version\": \"[0-9]+\.[0-9]+\.[0-9]+\"/\"version\": \"$NUEVA\"/" package.json
grep -q "\"version\": \"$NUEVA\"" package.json || { echo "No se pudo cambiar la versión"; exit 1; }

git commit -am "Versión $NUEVA"
git push -u origin "$RAMA"
gh pr create --base main --head "$RAMA" \
  --title "Versión $NUEVA" \
  --body "Cambio de versión para la demo del camino feliz."

echo
echo "Pull request creado. Cuando el check 'test' esté en verde, fusiónalo con:"
echo "  gh pr merge $RAMA --merge"
