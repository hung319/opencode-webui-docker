# ===============================
# OpenCode Web – Dockerfile
# Fix OAuth / Auth in container
# ===============================

FROM debian:stable-slim

LABEL maintainer="CezDev"

# -------------------------------
# 1. System dependencies
# -------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bash \
    tar \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# -------------------------------
# 2. Install OpenCode
# -------------------------------
RUN curl -fsSL https://opencode.ai/install | bash

# -------------------------------
# 3. Environment fixes for Docker
# -------------------------------
# Disable keyring (no DBus in container)
# Fix XDG paths so auth.json can be written
ENV PATH="/root/.opencode/bin:${PATH}" \
    OPENCODE_DISABLE_KEYRING=1 \
    XDG_DATA_HOME=/root/.local/share \
    XDG_CONFIG_HOME=/root/.config \
    XDG_RUNTIME_DIR=/tmp/runtime-root

# Create runtime dir required by auth backend
RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# -------------------------------
# 4. Working directory
# -------------------------------
WORKDIR /root

# -------------------------------
# 5. Expose Web UI port
# -------------------------------
EXPOSE 4096

# -------------------------------
# 6. Start OpenCode Web
# -------------------------------
# IMPORTANT:
# - 0.0.0.0 only for binding
# - Public access via domain/IP
CMD ["/bin/bash", "-c", \
  "exec opencode web --hostname ${OPENCODE_HOST:-0.0.0.0} --port ${OPENCODE_PORT:-4096}"]
