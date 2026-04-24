# ============================================================
# CNCC Portal – Flutter Web (Production Build)
# Stage 1 : Flutter builds the app  →  flutter build web
# Stage 2 : Python serves the output →  python -m http.server 3000
# ============================================================

# -----------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------
FROM debian:bookworm-slim AS builder

# System dependencies required by Flutter
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Flutter version pinned to exactly match local install (3.41.7 / Dart 3.11.5)
ENV FLUTTER_VERSION=3.41.7
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Clone Flutter SDK at the exact tag
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Bootstrap Flutter and pre-cache web artifacts
RUN flutter config --no-analytics \
    && flutter precache --web \
    && flutter doctor -v

WORKDIR /app

# Copy manifests first — pub get is cached unless these change
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the full source and build
COPY . .
RUN flutter build web --release

# -----------------------------------------------------------
# Stage 2: Serve with Python (tiny final image)
# -----------------------------------------------------------
FROM python:3.12-slim AS runner

WORKDIR /web

# Copy only the compiled web output from the builder stage
COPY --from=builder /app/build/web ./

EXPOSE 3000

# Serve on all interfaces so Docker port mapping works
CMD ["python", "-m", "http.server", "3000", "--bind", "0.0.0.0"]
