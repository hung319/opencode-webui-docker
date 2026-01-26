# --- Stage 1: Installer ---
FROM debian:stable-slim AS installer

# Cài đặt các dependencies cần thiết để chạy script install.sh
# Script yêu cầu: curl, tar (có sẵn hoặc cài thêm), bash
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Chạy lệnh cài đặt như yêu cầu
# Script sẽ cài binary vào $HOME/.opencode/bin (tức là /root/.opencode/bin)
RUN curl -fsSL https://opencode.ai/install | bash

# --- Stage 2: Runtime ---
FROM debian:stable-slim AS runtime

LABEL maintainer="CezDev"

# 1. Cài đặt dependencies tối thiểu cho runtime
# ca-certificates là bắt buộc để app giao tiếp HTTPS (tải model, auth, v.v.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2. Tạo user non-root (Security Best Practice)
RUN groupadd -r opencode && useradd -r -g opencode -u 1000 -m -s /bin/bash opencode

# 3. Copy binary từ Stage Installer
# Đường dẫn nguồn dựa trên logic của script: $HOME/.opencode/bin
COPY --from=installer /root/.opencode/bin/opencode /usr/local/bin/opencode

# 4. Cấp quyền thực thi
RUN chmod +x /usr/local/bin/opencode

# 5. Thiết lập môi trường
USER opencode
WORKDIR /home/opencode

# Cấu hình biến môi trường
# HOST=0.0.0.0 để container nhận request từ bên ngoài
ENV OPENCODE_SERVER_PASSWORD="changeme_secure_password"
ENV PORT=4096

# 6. Expose Port
EXPOSE 4096

# 7. Command khởi chạy
# Sử dụng exec form (mảng JSON) để signal handling hoạt động đúng (Ctrl+C để stop container)
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]
