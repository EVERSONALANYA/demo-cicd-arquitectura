# Etapa 1: instala solo las dependencias de producción
FROM node:24-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# Etapa 2: imagen final, mínima y actualizada
FROM node:24-alpine
# Aplica los parches de seguridad del sistema y quita npm/yarn (no se usan al ejecutar)
RUN apk upgrade --no-cache \
 && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
           /opt/yarn-* /usr/local/bin/yarn /usr/local/bin/yarnpkg
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

# Commit con el que se construyó la imagen (lo muestra /health)
ARG GIT_SHA=local
ENV GIT_SHA=$GIT_SHA

USER node
EXPOSE 3000
CMD ["node", "src/server.js"]
