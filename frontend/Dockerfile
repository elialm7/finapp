# ===== Build stage =====
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copiar dependencias primero para cache
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copiar el resto del proyecto
COPY . .

# Build arg que llega desde docker compose o docker build
ARG API_BASE_URL

# Compilar Flutter Web con dart-define
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# ===== Runtime stage =====
FROM nginx:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80