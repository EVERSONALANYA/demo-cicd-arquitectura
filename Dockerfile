# Etapa 1: instala solo las dependencias de producción
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# Etapa 2: imagen final, mínima, sin herramientas de desarrollo
FROM node:20-alpine
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
