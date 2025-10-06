FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
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

# Build web app
RUN flutter build web

# Expose port
EXPOSE 3000

# Command to run the application
CMD ["flutter", "run", "-d", "web-server", "--web-hostname", "0.0.0.0", "--web-port", "3000"]
