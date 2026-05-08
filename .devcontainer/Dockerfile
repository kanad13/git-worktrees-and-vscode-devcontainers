# Use the official Microsoft Ubuntu Dev Container image
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Update and install Python, Node.js, and tree
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    tree \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure python3 is the default 'python'
RUN ln -s /usr/bin/python3 /usr/bin/python
