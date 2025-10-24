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
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set Java 17 environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Flutter 3.16.9 (specific version)
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Switch to Flutter 3.16.9
RUN cd /flutter && git checkout 3.16.9

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
