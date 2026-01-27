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

# Build OpenChamber
RUN npm install -g @openchamber/web \
    && npm cache clean --force

# =========================================
# Runtime stage (DEBIAN STABLE)
# =========================================
FROM debian:stable

LABEL maintainer="CezDev"

ENV DEBIAN_FRONTEND=noninteractive

# Runtime deps
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
# Entrypoint (Fixed & Optimized)
# -----------------------------------------
# Sử dụng /bin/bash rõ ràng và logic mảng tường minh
RUN cat <<'EOF' > /usr/local/bin/entrypoint && chmod +x /usr/local/bin/entrypoint
#!/bin/bash
set -e

# 1. Khởi tạo mảng arg cơ bản
PORT="${OPENCHAMBER_PORT:-8080}"
# Lưu ý: Tách riêng từng phần tử mảng để an toàn nhất
ARGS=("openchamber" "--port" "$PORT")

# 2. Xử lý Password (Logic bạn cần)
if [[ -n "$OPENCHAMBER_UI_PASSWORD" ]]; then
    echo "🔒 Security: UI Password detected and applied."
    ARGS+=("--ui-password" "$OPENCHAMBER_UI_PASSWORD")
else
    echo "⚠️ Security: No UI Password set. Running in open mode."
fi

# 3. Xử lý Debug
if [[ "$OPENCHAMBER_DEBUG" == "true" ]]; then
    echo "🐛 Debug mode: ENABLED"
    ARGS+=("--debug")
    # In lệnh ra để debug (nhưng che password thực tế)
    PRINT_CMD="${ARGS[*]/$OPENCHAMBER_UI_PASSWORD/******}"
    echo "🚀 Executing command: $PRINT_CMD"
else
    echo "🚀 OpenChamber starting on port $PORT"
fi

# 4. Thực thi
exec "${ARGS[@]}"
EOF

WORKDIR /root

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint"]
