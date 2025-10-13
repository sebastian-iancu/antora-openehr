FROM node:18-bullseye

LABEL maintainer="openEHR Specifications Team"
LABEL description="Antora build environment for openEHR specifications"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    make \
    ruby \
    ruby-dev \
    build-essential \
    graphviz \
    && rm -rf /var/lib/apt/lists/*

# Install AsciiDoctor and extensions
RUN gem install \
    asciidoctor \
    asciidoctor-diagram \
    asciidoctor-kroki \
    rouge

# Install Antora and related Node packages
RUN npm install -g \
    @antora/cli@3.1 \
    @antora/site-generator@3.1 \
    @antora/lunr-extension \
    asciidoctor-kroki

# Create working directories
RUN mkdir -p /workspace /build

# Set working directory
WORKDIR /workspace

# Copy package.json if exists (for additional Node dependencies)
# This will be created in the migration repository

# Default command
CMD ["/bin/bash"]

# For building: docker run --rm -v $(pwd):/workspace openehr-antora make build
