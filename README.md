# demo-cicd

API de demostración para la exposición de CI/CD — Arquitectura de Software (UNSCH).

**Guía completa paso a paso:** [docs/GUIA_DEMO.md](docs/GUIA_DEMO.md)

## Contenido

| Archivo | Qué hace |
| --- | --- |
| `src/app.js`, `src/server.js` | API Express con `/` (página con la versión) y `/health` |
| `test/app.test.js` | Pruebas unitarias (quality gate) |
| `Dockerfile` | Imagen multi-stage sobre `node:20-alpine` |
| `.github/workflows/ci-cd.yml` | Pipeline: test → build + Trivy + GHCR → deploy en Render + health check |
| `scripts/cambiar-version.sh` | Escenario 1: cambia la versión y abre el pull request |
| `scripts/preparar-error.sh` | Escenario 2: abre un pull request con un error a propósito |
| `scripts/dora.sh` | Calcula las 4 métricas DORA del historial del pipeline |

## Configuración necesaria en GitHub

- Entorno `production` con el secreto `RENDER_DEPLOY_HOOK` (y revisores opcionales).
- Variable `APP_URL` con la URL pública de Render, sin `/` final.
- Protección de `main`: pull request obligatorio y check `test` requerido.

## Probar en local (opcional)

```bash
npm install
npm test
npm start          # http://localhost:3000 y http://localhost:3000/health
```
