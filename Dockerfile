# ===============================
# Builder
# ===============================
FROM debian:stable AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    python3 \
    make \
    g++ \
    build-essential \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/*

# Install OpenChamber
RUN npm install -g @openchamber/web \
 && npm cache clean --force

# ===============================
# Runtime
# ===============================
FROM debian:stable-slim
ENV DEBIAN_FRONTEND=noninteractive

# Minimal runtime deps (+ curl REQUIRED)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    openssl \
    libstdc++6 \
    libgcc-s1 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc /usr/share/man

# Node.js runtime only
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/share/doc /usr/share/man

# Cloudflared
RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    -o /usr/local/bin/cloudflared \
 && chmod +x /usr/local/bin/cloudflared

# OpenChamber
COPY --from=builder /usr/lib/node_modules/@openchamber/web /usr/lib/node_modules/@openchamber/web
RUN ln -sf /usr/lib/node_modules/@openchamber/web/bin/openchamber /usr/bin/openchamber

# OpenCode CLI (no auto start)
RUN curl -fsSL https://opencode.ai/install | bash

# Env fixes
ENV PATH="/root/.opencode/bin:${PATH}" \
    OPENCODE_DISABLE_KEYRING=1 \
    OPENCODE_SKIP_START=true \
    XDG_RUNTIME_DIR=/tmp/runtime-root

RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# ===============================
# OpenChamber ENV
# ===============================
ENV OPENCHAMBER_HOST=0.0.0.0 \
    OPENCHAMBER_PORT=3000 \
    OPENCHAMBER_ARGS=

WORKDIR /root
EXPOSE 3000

CMD ["sh", "-c", "\
exec openchamber \
 --host ${OPENCHAMBER_HOST} \
 --port ${OPENCHAMBER_PORT} \
 ${OPENCHAMBER_UI_PASSWORD:+--ui-password ${OPENCHAMBER_UI_PASSWORD}} \
 ${OPENCHAMBER_ARGS} \
"]
