# =========================================
# Stage 1: Builder
# =========================================
FROM node:20-bookworm-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-dev make g++ build-essential ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @openchamber/web@1.5.8 \
    && npm cache clean --force

# =========================================
# Stage 2: Runtime
# =========================================
FROM debian:stable
LABEL maintainer="CezDev"

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.opencode/bin:/usr/local/bin:${PATH}" \
    OPENCODE_DISABLE_KEYRING=1 \
    XDG_DATA_HOME=/root/.local/share \
    OPENCHAMBER_PORT=8080

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl bash openssl libstdc++6 libgcc-s1 python3 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local
RUN curl -fsSL https://opencode.ai/install | bash

RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# -----------------------------------------
# Entrypoint: SUPERVISOR (Người giám hộ)
# -----------------------------------------
# Script này đóng vai trò là PID 1 để giữ container luôn sống
RUN cat <<'EOF' > /usr/local/bin/entrypoint && chmod +x /usr/local/bin/entrypoint
#!/bin/bash
set -e

# Xử lý khi bạn muốn tắt Docker bằng lệnh stop
term_handler() {
  if [ -n "$child_pid" ]; then
    kill -SIGTERM "$child_pid" 2>/dev/null
    wait "$child_pid"
  fi
  exit 0
}
trap 'term_handler' SIGTERM INT

ARGS=("openchamber" "--port" "${OPENCHAMBER_PORT:-8080}")
[[ -n "$OPENCHAMBER_UI_PASSWORD" ]] && ARGS+=("--ui-password" "$OPENCHAMBER_UI_PASSWORD")
[[ "$OPENCHAMBER_DEBUG" == "true" ]] && ARGS+=("--debug")

echo "🚀 Starting Supervisor wrapper..."

# Vòng lặp vô tận: Nếu App tắt, ta bật lại ngay
while true; do
    echo "⚡ Launching OpenChamber..."
    
    # Chạy app ở background (&) để script này không bị block
    "${ARGS[@]}" &
    child_pid=$!
    
    # Script nằm chờ ở đây cho đến khi App tắt
    wait "$child_pid"
    
    # App đã tắt (do update xong), chờ 5s rồi lặp lại để khởi động bản mới
    echo "♻️ OpenChamber exited. Restarting in 5 seconds..."
    sleep 5
done
EOF

WORKDIR /root
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/entrypoint"]
