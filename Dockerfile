# =========================================
# Builder stage
# =========================================
FROM node:20-bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-dev make g++ build-essential ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @openchamber/web && npm cache clean --force

# =========================================
# Runtime stage
# =========================================
FROM debian:stable

LABEL maintainer="CezDev"
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.opencode/bin:/usr/local/bin:${PATH}" \
    OPENCODE_DISABLE_KEYRING=1 \
    XDG_DATA_HOME=/root/.local/share \
    OPENCHAMBER_PORT=8080

# Install minimal deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl bash openssl libstdc++6 libgcc-s1 python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local
RUN curl -fsSL https://opencode.ai/install | bash

RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# -----------------------------------------
# Entrypoint (Compact Version)
# -----------------------------------------
RUN cat <<'EOF' > /usr/local/bin/entrypoint && chmod +x /usr/local/bin/entrypoint
#!/bin/bash
set -e

# Khởi tạo lệnh cơ bản
ARGS=("openchamber" "--port" "${OPENCHAMBER_PORT:-8080}")

# Logic thêm argument gọn gàng
[[ -n "$OPENCHAMBER_UI_PASSWORD" ]] && ARGS+=("--ui-password" "$OPENCHAMBER_UI_PASSWORD")
[[ "$OPENCHAMBER_DEBUG" == "true" ]] && ARGS+=("--debug")

echo "🚀 Starting OpenChamber on port ${OPENCHAMBER_PORT:-8080}..."
exec "${ARGS[@]}"
EOF

WORKDIR /root
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint"]
