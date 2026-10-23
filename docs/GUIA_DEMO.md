# Guía completa de la demo CI/CD

Exposición de CI/CD — Arquitectura de Software (UNSCH).
Demo operada por **Kevin**; entorno de Render preparado por **Verton**.

---

## Qué demuestra la demo

| Parte | Qué se ve | Tema relacionado |
|---|---|---|
| 1. Camino feliz | Un cambio de versión llega solo a producción | Pipeline, despliegue continuo |
| 2. Quality gate | Un cambio con error queda bloqueado | Pruebas, Shift-Left |
| 3. Health check y rollback | `/health` confirma la versión; botón de rollback | Resiliencia |
| 4. Métricas DORA | Métricas calculadas del historial del pipeline | DevSecOps y métricas |

El escaneo de seguridad (Trivy) se ve dentro del pipeline de la parte 1.

---

## 0. Lo que necesitas

- Cuenta de **GitHub** y cuenta de **Render** (se crea con la de GitHub).
- **Ubuntu** (o WSL) con estas herramientas:

```bash
sudo apt update
sudo apt install -y git unzip gh jq
```

- Configurar Git (solo la primera vez):

```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-correo@ejemplo.com"
```

- Iniciar sesión en GitHub desde la terminal:

```bash
gh auth login
```

Responde: GitHub.com → HTTPS → Yes → Login with a web browser. Copia el código que aparece y autorízalo en el navegador.

Node.js y Docker **no son necesarios**: las pruebas y la imagen se ejecutan en GitHub Actions.

---

## 1. Subir el proyecto a GitHub

```bash
cd ~/Descargas            # o ~/Downloads
unzip demo-cicd-completo.zip
cd demo-cicd
git init
git add .
git commit -m "Proyecto base de la demo"
git branch -M main
gh repo create demo-cicd --public --source=. --push
```

El repo debe ser **público**: así la protección de ramas y los revisores del entorno son gratuitos.

---

## 2. Primera ejecución y paquete público

1. Abre el repo en el navegador: `gh repo view --web`.
2. Pestaña **Actions**: `test` y `build` terminan en verde; `deploy` **falla** porque Render aún no existe. Es normal.
3. Haz pública la imagen: en tu perfil de GitHub → **Packages** → `demo-cicd` → **Package settings** → **Change visibility** → **Public**.
4. Copia la **etiqueta** de la imagen (el código largo del commit) que aparece en la página del paquete.

---

## 3. Crear el servicio en Render

1. render.com → **New** → **Web Service** → **Existing Image**.
2. **Image URL:** `ghcr.io/<tu-usuario-en-minúsculas>/demo-cicd:<etiqueta>`
3. **Name:** `demo-cicd` · **Region:** la más cercana · **Instance type:** **Free**.
4. **Environment variables:** `NODE_ENV` = `production` (el puerto lo asigna Render en `PORT`).
5. Crea el servicio y espera el estado **Live**.
6. Abre `https://<tu-servicio>.onrender.com/health` → debe responder `{"status":"healthy","version":"1.0.0",...}`.
7. **Settings** → **Health Check Path** = `/health`.
8. **Settings** → **Deploy Hook** → **copia la URL**. Es una contraseña: no la pongas en el código ni en las diapositivas.

---

## 4. Configurar GitHub

En el repo → **Settings**:

**4.1 Entorno `production`**
- **Environments** → **New environment** → `production`.
- **Environment secrets** → `RENDER_DEPLOY_HOOK` = la URL del paso 3.8.
- **Required reviewers** → agrega a **Kevin** (y a ti como respaldo). Así el despliegue espera aprobación: es la **entrega continua** que se explica en la exposición. Si lo quitas, es **despliegue continuo**.
- Kevin necesita acceso al repo: **Settings → Collaborators → Add people**.

**4.2 Variable `APP_URL`**
- **Secrets and variables → Actions → Variables → New repository variable**.
- `APP_URL` = `https://<tu-servicio>.onrender.com` (sin `/` al final).

**4.3 Proteger la rama `main`**
- **Branches → Add classic branch protection rule** (o **Rulesets**, según tu pantalla).
- Branch name pattern: `main`.
- Activa **Require a pull request before merging** (desactiva "Require approvals" para no frenar la demo).
- Activa **Require status checks to pass** y busca el check **`test`** (aparece después de la primera ejecución).
- Guarda.

---

## 5. Primera prueba completa

```bash
./scripts/cambiar-version.sh 1.1.0
```

1. El script crea la rama, cambia la versión y abre el pull request.
2. Espera a que el check `test` esté en verde: `gh pr checks --watch`.
3. Fusiona: `gh pr merge version-1-1-0 --merge`.
4. Sigue el pipeline: `gh run watch`.
5. Si activaste revisores, el job `deploy` espera: en **Actions** → la ejecución → **Review deployments** → **Approve and deploy**.
6. En Render (**Events**) aparece el despliegue de la imagen nueva.
7. El paso **Health check** termina en verde cuando `/health` responde con el commit nuevo.
8. Recarga la URL: **Versión 1.1.0**.

**Cronometra desde el merge hasta el health check verde.** Ese es el tiempo que la exposición debe cubrir antes de la demo.

---

## 6. Preparar el escenario 2 (antes de exponer)

```bash
./scripts/preparar-error.sh
```

Crea la rama `error-demo` con un error a propósito (el porcentaje de asistencia se multiplica por 10 en vez de 100) y abre su pull request. La prueba falla y el merge queda **bloqueado**. **Nunca fusiones ese PR.**

---

## 7. Métricas DORA

```bash
./scripts/dora.sh 30      # últimos 30 días
```

Muestra la frecuencia de despliegue, el lead time, la tasa de fallo y el tiempo de recuperación, calculados del historial de GitHub Actions. Con pocos ensayos los números son pequeños; mientras más ensayen, más datos habrá. Puedes llevar una captura de la salida para Pozo.

---

## 8. Rollback

Dos formas de mostrarlo:

- **Render:** pestaña **Events** (o **Deploys**) → en un despliegue anterior → **Rollback**. Vuelve a la versión previa sin recompilar.
- **Por etiqueta:** como cada imagen queda guardada en GHCR con su commit, se puede volver a desplegar cualquier etiqueta anterior. Esto conecta con el artefacto inmutable.

Para la demo basta con **mostrar el botón**; ejecutarlo lleva tiempo.

---

## 9. Día de la exposición

**La noche anterior**
- [ ] Hacer un ensayo completo y grabarlo en video (respaldo).
- [ ] Producción en la versión actual (por ejemplo `1.1.0`); el cambio en vivo será a la siguiente (`1.2.0`).
- [ ] PR del escenario 2 abierto y en rojo.

**30 minutos antes**
- [ ] Abrir la URL de Render para despertar el servicio (el plan gratuito se duerme tras 15 minutos sin tráfico). Repetir 2–3 minutos antes de empezar.
- [ ] Preparar el cambio de versión **sin fusionar**: `./scripts/cambiar-version.sh 1.2.0` y esperar el check `test` en verde.
- [ ] Tener abiertas las pestañas: PR del cambio, **Actions**, Render (**Events**), la URL en `/health`, PR de `error-demo`.
- [ ] Copiar la salida de `./scripts/dora.sh`.

**Minuto 1 (mientras Verton abre la exposición)**
- [ ] Kevin fusiona el PR: `gh pr merge version-1-2-0 --merge`. Verton lo anuncia.

**Minuto 12:30 — Demo (Kevin, 4 minutos)**

1. **Camino feliz (1:30).** "Al inicio fusionamos un cambio." Recorrer el pipeline en **Actions**: pruebas, imagen, escaneo Trivy, despliegue. Si espera aprobación: "este clic es la diferencia entre entrega y despliegue continuo" → **Approve**. Mostrar Render desplegando y recargar la URL: **1.2.0**.
2. **Quality gate (1:00).** Abrir el PR `error-demo` en rojo: "la prueba detectó el error; el merge está bloqueado; este error nunca llegará a producción."
3. **Health check y rollback (1:00).** Mostrar `/health` con la versión y el commit nuevos. Mostrar el botón **Rollback** en Render: "si algo fallara, volvemos a la versión anterior en un clic."
4. **Métricas (0:30).** Mostrar la salida de `dora.sh`: "de este historial salen las métricas DORA." Pasar la palabra a Pozo.

---

## 10. Si algo falla

| Síntoma | Causa probable | Solución |
|---|---|---|
| `deploy` falla al llamar al hook | Secreto mal copiado, o la imagen no coincide con la del servicio | Copiar de nuevo el hook; usuario y nombre de imagen iguales a los de Render, en minúsculas |
| Render no descarga la imagen | Paquete de GHCR privado | Paso 2.3 |
| El health check agota el tiempo | Servicio dormido o despliegue lento | Despertar la URL antes; volver a ejecutar el job |
| `build` falla en Trivy | Vulnerabilidad alta en la imagen base | Reconstruir más tarde o actualizar la imagen base; avisar a Pozo |
| No se puede hacer push a `main` | La rama está protegida | Correcto: los cambios van por pull request |
| `cambiar-version.sh` dice que la rama existe | Ya se usó esa versión | Usar la siguiente versión (`1.3.0`, etc.) |
| Falla el internet en la exposición | — | Poner el video grabado |

---

## Seguridad

La acción de Trivy se fija en `aquasecurity/trivy-action@v0.36.0`. En marzo de 2026, esa acción sufrió un ataque a su cadena de suministro que alteró casi todas sus versiones anteriores para robar credenciales. No usar `@master` ni versiones sin el prefijo `v`.
