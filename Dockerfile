FROM debian:stable

LABEL maintainer="CezDev"

# Thiết lập biến môi trường
ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/root/.opencode/bin:/usr/local/bin:${PATH}" \
    OPENCODE_DISABLE_KEYRING=1 \
    XDG_DATA_HOME=/root/.local/share \
    OPENCHAMBER_PORT=8080 \
    TERM=xterm-256color \
    SHELL=/bin/bash

# 1. Cài đặt toàn bộ dependencies trong 1 lần để giảm layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    bash \
    git \
    python3 \
    python3-dev \
    make \
    g++ \
    build-essential \
    nodejs \
    npm \
    openssl \
    libstdc++6 \
    libgcc-s1 \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# 2. Cài đặt các công cụ bổ trợ
# Copy binary uv từ image có sẵn cho nhanh
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# 3. Cài đặt OpenChamber và OpenCode trực tiếp trên môi trường này
RUN npm install -g @openchamber/web@latest && npm cache clean --force
RUN curl -fsSL https://opencode.ai/install | bash

# 4. Cấu hình môi trường làm việc
WORKDIR /root
RUN mkdir -p /root/.local/share /tmp/runtime-root && \
    chmod -R 700 /root && \
    chmod 1777 /tmp

# 5. Entrypoint script
RUN cat <<'EOF' > /usr/local/bin/entrypoint && chmod +x /usr/local/bin/entrypoint
#!/bin/bash
set -e

# Đảm bảo các thư mục cần thiết tồn tại để tránh shell crash
mkdir -p /root/.local/share

ARGS=("openchamber" "--port" "${OPENCHAMBER_PORT:-8080}")

[[ -n "$OPENCHAMBER_UI_PASSWORD" ]] && ARGS+=("--ui-password" "$OPENCHAMBER_UI_PASSWORD")
[[ "$OPENCHAMBER_DEBUG" == "true" ]] && ARGS+=("--debug")

echo "🚀 Starting OpenChamber on port ${OPENCHAMBER_PORT:-8080}..."
exec "${ARGS[@]}"
EOF

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entrypoint"]
