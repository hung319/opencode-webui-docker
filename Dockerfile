# --- Stage 1: Installer ---
FROM debian:stable-slim AS installer

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://opencode.ai/install | bash

# --- Stage 2: Runtime ---
FROM debian:stable-slim AS runtime

LABEL maintainer="CezDev"

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -r opencode && useradd -r -g opencode -u 1000 -m -s /bin/bash opencode

COPY --from=installer /root/.opencode/bin/opencode /usr/local/bin/opencode
RUN chmod +x /usr/local/bin/opencode

USER opencode
WORKDIR /home/opencode

# Lưu ý: Không còn giá trị mặc định nào được set tại đây.
# Người dùng BẮT BUỘC phải truyền biến môi trường khi chạy container.
EXPOSE 4096

# --- COMMAND KHỞI CHẠY ---
# Sử dụng fallback :-0.0.0.0 và :-4096 để tránh lỗi cú pháp lệnh nếu bạn quên truyền biến này.
# User/Password sẽ được ứng dụng tự đọc từ biến môi trường (ENV) mà bạn truyền vào.
CMD ["/bin/bash", "-c", "exec opencode web --hostname ${OPENCODE_HOST:-0.0.0.0} --port ${OPENCODE_PORT:-4096}"]
