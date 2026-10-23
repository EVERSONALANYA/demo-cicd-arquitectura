#!/usr/bin/env bash
# Escenario 2 (quality gate): sube un cambio con un error a propósito en una rama
# aparte y abre un pull request. Las pruebas fallarán y el merge quedará bloqueado.
# Ejecútalo ANTES de la exposición, para que el check ya esté en rojo.
set -euo pipefail

RAMA="error-demo"

git checkout main
git pull --ff-only
git checkout -B "$RAMA"

# Error deliberado: el porcentaje de asistencia se calcula mal (multiplica por 10 en vez de 100)
sed -i 's/(presentes \/ total) \* 100/(presentes \/ total) * 10/' src/app.js
grep -q '(presentes / total) \* 10)' src/app.js || { echo "No se pudo introducir el error"; exit 1; }

git commit -am "Cambio con error (demo del quality gate)"
git push -u --force origin "$RAMA"
gh pr create --base main --head "$RAMA" \
  --title "Cambio con error (demo del quality gate)" \
  --body "Este PR tiene un error a propósito. Las pruebas deben fallar y el merge debe quedar bloqueado. NO FUSIONAR." \
  || echo "El pull request ya existía; se actualizó con el nuevo commit."

git checkout main
echo
echo "Listo. En la pestaña Pull requests verás el check 'test' en rojo y el merge bloqueado."
