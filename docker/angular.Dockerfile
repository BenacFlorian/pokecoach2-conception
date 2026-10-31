# Build context: pokecoach2 workspace root (parent of pokecoach2-conception).
FROM node:22.23.3-bookworm AS build
WORKDIR /src/pokecoach-angular
COPY pokecoach2-angular/pokecoach-angular/package.json pokecoach2-angular/pokecoach-angular/package-lock.json ./
RUN npm ci
COPY pokecoach2-angular/pokecoach-angular/ ./
RUN npm run build

FROM nginx:1.27.4-alpine
COPY pokecoach2-conception/docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /src/pokecoach-angular/dist/pokecoach-angular/browser /usr/share/nginx/html
HEALTHCHECK CMD wget -qO- http://127.0.0.1/healthz || exit 1
