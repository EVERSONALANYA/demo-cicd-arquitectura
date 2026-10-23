#!/usr/bin/env bash
# Calcula una aproximación de las 4 métricas DORA a partir del historial
# de ejecuciones del workflow CI-CD en la rama main (GitHub Actions).
# Requiere: gh (con sesión iniciada) y jq.
# Uso: ./scripts/dora.sh [días]   (por defecto, los últimos 30 días)
set -euo pipefail

DIAS="${1:-30}"
DESDE="$(date -u -d "-${DIAS} days" +%Y-%m-%dT%H:%M:%SZ)"

RUNS_FILE="${RUNS_FILE:-}"
if [[ -z "$RUNS_FILE" ]]; then
  RUNS_FILE="$(mktemp)"
  gh run list --workflow ci-cd.yml --branch main --event push --limit 200 \
    --json databaseId,conclusion,status,createdAt,updatedAt,headSha > "$RUNS_FILE"
fi

jq -r --arg desde "$DESDE" --argjson dias "$DIAS" '
  def ts: fromdateiso8601;
  def fmt(m): if m == null then "sin datos"
              elif m < 60 then "\(m | floor) min"
              else "\((m / 60) * 10 | floor / 10) h" end;

  [ .[] | select(.status == "completed" and .createdAt >= $desde) ]
  | sort_by(.createdAt) as $runs
  | ($runs | length) as $total
  | ($runs | map(select(.conclusion == "success"))) as $ok
  | ($runs | map(select(.conclusion == "failure"))) as $fail

  # Lead time aproximado: desde que el cambio llega a main hasta que termina el despliegue
  | ($ok | map((.updatedAt | ts) - (.createdAt | ts)) | if length > 0 then add / length / 60 else null end) as $lead

  # MTTR aproximado: desde cada fallo hasta el siguiente despliegue exitoso
  | ([ range(0; $runs | length) as $i
       | select($runs[$i].conclusion == "failure")
       | ($runs[$i+1:] | map(select(.conclusion == "success")) | first) as $fix
       | select($fix != null)
       | (($fix.updatedAt | ts) - ($runs[$i].updatedAt | ts)) / 60 ]
     | if length > 0 then add / length else null end) as $mttr

  | "Métricas DORA (últimos \($dias) días, rama main)",
    "--------------------------------------------------",
    "1. Frecuencia de despliegue:   \($ok | length) despliegues exitosos (\((($ok | length) / ($dias / 7)) * 10 | floor / 10) por semana)",
    "2. Lead time de cambios:       \(fmt($lead)) en promedio (de main a producción)",
    "3. Tasa de fallo de cambios:   \(if $total > 0 then (($fail | length) * 100 / $total | floor) else 0 end)% (\($fail | length) de \($total) ejecuciones)",
    "4. Tiempo de recuperación:     \(fmt($mttr)) en promedio (de un fallo al siguiente despliegue exitoso)"
' "$RUNS_FILE"
