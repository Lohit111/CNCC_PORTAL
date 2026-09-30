FROM ghcr.io/cirruslabs/flutter:3.41.7 AS builder

ENV FLUTTER_WEB_USE_SKIA=true

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get

COPY . .

RUN --mount=type=cache,target=/root/.pub-cache \
    flutter build web --release


FROM nginx:alpine AS runner

RUN apk add --no-cache openssl && \
    mkdir -p /etc/nginx/certs && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/selfsigned.key \
    -out /etc/nginx/certs/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=localhost"

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80 443