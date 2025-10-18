FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Enable web support
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./

# Create pubspec.lock if it doesn't exist
RUN touch pubspec.lock

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# ⚠️ BUILD RUNNER KALDIRILDI - Projede build_runner gerektiren paketler yok!
# Build_runner gerektirmeyen yaklaşım kullanıldı (riverpod, json_serializable vs)

# Flutter web build
RUN flutter build web --release

# Expose port
EXPOSE 3000

# Command to run the application
CMD ["python3", "-m", "http.server", "3000", "--directory", "build/web"]
