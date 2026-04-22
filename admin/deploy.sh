#!/bin/bash
# Chạy từ máy tính của bạn (Git Bash / WSL)
# Usage: bash deploy.sh [--first]
#   --first : lần đầu deploy, sẽ cài đặt VPS
#   (không có flag): chỉ update code

set -e

VPS_IP="160.22.170.223"
VPS_USER="root"
APP_DIR="/var/www/senvpn-admin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Kiểm tra .env.local ────────────────────────────────────────────────────
if grep -q "PASTE_WEB_APP_ID_HERE" "$SCRIPT_DIR/.env.local"; then
  echo ""
  echo "⚠️  Bạn cần điền Firebase App ID trước khi deploy!"
  echo ""
  echo "   1. Mở trình duyệt, vào: https://console.firebase.google.com/project/sen-vpn-3cca3/settings/general"
  echo "   2. Kéo xuống phần 'Your apps'"
  echo "   3. Nếu chưa có web app: Click biểu tượng </> → Đặt tên 'Admin' → Register"
  echo "   4. Copy giá trị appId (dạng: 1:284800524184:web:xxxxxxxx)"
  echo "   5. Mở file: admin/.env.local"
  echo "   6. Thay PASTE_WEB_APP_ID_HERE bằng giá trị vừa copy"
  echo "   7. Chạy lại lệnh này"
  echo ""
  exit 1
fi

echo "=== SEN VPN Admin Panel — Deploy to $VPS_IP ==="

# ─── BƯỚC 1: Lần đầu — cài đặt VPS ─────────────────────────────────────────
if [[ "$1" == "--first" ]]; then
  echo ""
  echo ">>> Cài đặt VPS lần đầu (sẽ hỏi mật khẩu root VPS)..."
  echo ""

  # Tạo SSH key nếu chưa có
  if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "senvpn-admin"
    echo "✅ Đã tạo SSH key"
  fi

  # Copy SSH key lên VPS
  echo ">>> Nhập mật khẩu root VPS để copy SSH key (chỉ cần làm 1 lần):"
  cat ~/.ssh/id_rsa.pub | ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP \
    "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  echo "✅ SSH key đã được copy lên VPS — từ giờ không cần nhập password nữa"

  # Upload và chạy vps-setup.sh
  echo ""
  echo ">>> Đang cài đặt Node.js, PM2, Nginx, SSL... (mất ~3 phút)"
  scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/vps-setup.sh" $VPS_USER@$VPS_IP:/tmp/vps-setup.sh
  ssh $VPS_USER@$VPS_IP "bash /tmp/vps-setup.sh"
fi

# ─── BƯỚC 2: Build app locally ──────────────────────────────────────────────
echo ""
echo ">>> Đang cài dependencies và build..."
cd "$SCRIPT_DIR"
npm install --legacy-peer-deps
npm run build

# ─── BƯỚC 3: Upload files lên VPS ───────────────────────────────────────────
echo ""
echo ">>> Đang upload lên VPS..."
ssh -o StrictHostKeyChecking=no $VPS_USER@$VPS_IP "mkdir -p $APP_DIR"

rsync -az --delete \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='.next/cache' \
  "$SCRIPT_DIR/" \
  $VPS_USER@$VPS_IP:$APP_DIR/

# ─── BƯỚC 4: Cài dependencies và restart trên VPS ───────────────────────────
echo ""
echo ">>> Khởi động app trên VPS..."
ssh $VPS_USER@$VPS_IP << REMOTE
  cd $APP_DIR
  npm install --legacy-peer-deps --production
  pm2 describe senvpn-admin > /dev/null 2>&1 && \
    pm2 restart senvpn-admin || \
    pm2 start npm --name senvpn-admin -- start
  pm2 save
REMOTE

echo ""
echo "✅ Deploy hoàn tất!"
echo ""
echo "   🌐 Admin Panel: https://lephap.io.vn"
echo "   📊 Xem logs:    ssh root@$VPS_IP 'pm2 logs senvpn-admin'"
echo ""
