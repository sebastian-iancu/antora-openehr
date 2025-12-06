FROM node:18-bullseye

LABEL maintainer="openEHR Specifications Team"
LABEL description="Antora build environment for openEHR specifications"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    make \
    bash \
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

# Create working directories
WORKDIR /workspace
RUN mkdir 0755 -p /workspace/node_modules /workspace/build /home/node/.npm \
   && chown -R node:node /workspace /home/node/.npm
ENV PATH="/workspace/node_modules/.bin:$PATH"

# Install Antora and related Node packages
USER node

# Copy package.json if exists (for additional Node dependencies)
# This will be created in the migration repository

# Default command
CMD ["/bin/bash"]

# For building: docker run --rm -v $(pwd):/workspace antora-openehr make build
