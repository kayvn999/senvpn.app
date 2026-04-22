#!/bin/bash
# Runs ON the VPS — installs Node, PM2, Nginx, SSL
set -e

DOMAIN="lephap.io.vn"
APP_DIR="/var/www/senvpn-admin"

echo "=== [1/6] Cập nhật hệ thống ==="
apt-get update -y && apt-get upgrade -y

echo "=== [2/6] Cài Node.js 20 ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

echo "=== [3/6] Cài PM2, Nginx, Certbot ==="
npm install -g pm2
apt-get install -y nginx certbot python3-certbot-nginx

echo "=== [4/6] Tạo thư mục app ==="
mkdir -p $APP_DIR

echo "=== [5/6] Cấu hình Nginx ==="
cat > /etc/nginx/sites-available/senvpn-admin << 'NGINX'
server {
    listen 80;
    server_name lephap.io.vn www.lephap.io.vn;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/senvpn-admin /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo "=== [6/6] Lấy SSL từ Let's Encrypt ==="
certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN || \
  echo "SSL thất bại — có thể DNS chưa trỏ về VPS. Bỏ qua, thử lại sau với: certbot --nginx -d $DOMAIN"

# PM2 tự khởi động khi VPS reboot
pm2 startup systemd -u root --hp /root | tail -1 | bash || true

echo ""
echo "✅ VPS setup hoàn tất!"
