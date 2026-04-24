# ============================================================
# CNCC Portal – Flutter Web (Development Server)
# Starts with: flutter run -d web-server --web-port=3000
# ============================================================

# -----------------------------------------------------------
# Stage 1: Flutter SDK + dependencies
# -----------------------------------------------------------
FROM debian:bookworm-slim AS flutter-base

# Install system dependencies required by Flutter and pub
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Flutter version pinned to exactly match the local install (3.41.7 / Dart 3.11.5)
ENV FLUTTER_VERSION=3.41.7
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

# Download and install Flutter
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Pre-cache Flutter web artifacts so they don't need re-downloading at runtime
RUN flutter config --no-analytics \
    && flutter precache --web \
    && flutter doctor -v

# -----------------------------------------------------------
# Stage 2: App image
# -----------------------------------------------------------
FROM flutter-base AS app

WORKDIR /app

# Copy dependency manifests first (better layer caching)
COPY pubspec.yaml pubspec.lock ./

# Fetch all pub dependencies
RUN flutter pub get

# Copy the rest of the source code
COPY . .

# Expose the web-server port
EXPOSE 3000

# Start the Flutter web development server
CMD ["flutter", "run", "-d", "web-server", "--web-port=3000", "--web-hostname=0.0.0.0"]
