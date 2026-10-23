#!/usr/bin/env bash
# Escenario 1 (camino feliz): cambia la versión de la app y abre un pull request.
# Uso: ./scripts/cambiar-version.sh 1.1.0
set -euo pipefail

NUEVA="${1:?Indica la versión nueva, por ejemplo: ./scripts/cambiar-version.sh 1.1.0}"
RAMA="version-${NUEVA//./-}"

git checkout main
git pull --ff-only
git checkout -b "$RAMA"

# Cambia el campo "version" de package.json (y de package-lock.json) sin crear un tag
npm version "$NUEVA" --no-git-tag-version >/dev/null

git commit -am "Versión $NUEVA"
git push -u origin "$RAMA"
gh pr create --base main --head "$RAMA" \
  --title "Versión $NUEVA" \
  --body "Cambio de versión para la demo del camino feliz."

echo
echo "Pull request creado. Cuando el check 'test' esté en verde, fusiónalo con:"
echo "  gh pr merge $RAMA --merge"
