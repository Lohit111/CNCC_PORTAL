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

COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80