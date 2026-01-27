# Sử dụng Debian Stable Slim để cân bằng giữa kích thước và tính ổn định
FROM debian:stable-slim

LABEL maintainer="CezDev"

# 1. Cài đặt các gói cần thiết:
# - curl, ca-certificates: Để tải bộ cài và giao tiếp HTTPS
# - bash, tar: Để chạy script cài đặt và giải nén
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    tar \
    && rm -rf /var/lib/apt/lists/*

# 2. Cài đặt opencode
# Script sẽ tự động cài vào /root/.opencode/bin vì đang chạy user root
RUN curl -fsSL https://opencode.ai/install | bash

. /root/.bashrc

# 4. Thiết lập thư mục làm việc
WORKDIR /root

# 5. Khai báo cổng
EXPOSE 4096

# 6. Lệnh khởi chạy
# Sử dụng 'exec' để giữ PID 1.
# Hostname và Port có fallback giá trị mặc định nếu bạn quên truyền.
# Username/Password KHÔNG có mặc định (bắt buộc truyền khi run).
CMD ["/bin/bash", "-c", "exec opencode web --hostname ${OPENCODE_HOST:-0.0.0.0} --port ${OPENCODE_PORT:-4096}"]
