# =========================================
# Builder stage
# =========================================
FROM node:20-bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-dev \
    make \
    g++ \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Build OpenChamber (native deps)
RUN npm install -g @openchamber/web \
    && npm cache clean --force


# =========================================
# Runtime stage (DEBIAN STABLE)
# =========================================
FROM debian:stable

LABEL maintainer="CezDev"

ENV DEBIAN_FRONTEND=noninteractive

# Runtime deps (tối thiểu)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bash \
    openssl \
    libstdc++6 \
    libgcc-s1 \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy Node.js + global npm packages
COPY --from=builder /usr/local /usr/local

# Install OpenCode CLI
RUN curl -fsSL https://opencode.ai/install | bash

# Runtime ENV
ENV PATH="/root/.opencode/bin:/usr/local/bin:${PATH}" \
    OPENCODE_DISABLE_KEYRING=1 \
    XDG_DATA_HOME=/root/.local/share \
    XDG_CONFIG_HOME=/root/.config \
    XDG_RUNTIME_DIR=/tmp/runtime-root \
    OPENCHAMBER_PORT=8080

RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# -----------------------------------------
# Entrypoint
# -----------------------------------------
RUN cat <<'EOF' > /usr/local/bin/entrypoint && chmod +x /usr/local/bin/entrypoint
#!/usr/bin/env bash
set -e

PORT="${OPENCHAMBER_PORT:-8080}"

ARGS=(openchamber --port "$PORT")

[ -n "$OPENCHAMBER_UI_PASSWORD" ] && ARGS+=(--ui-password "$OPENCHAMBER_UI_PASSWORD")
[ "$OPENCHAMBER_DEBUG" = "true" ] && ARGS+=(--debug)

echo "🚀 OpenChamber starting on port $PORT"
exec "${ARGS[@]}"
EOF

WORKDIR /root

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint"]
