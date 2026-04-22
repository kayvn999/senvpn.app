# Setup OpenVPN Server trên VPS

**OS:** Ubuntu 22.04  
**Port:** 1194 (UDP)  
**Script:** angristan/openvpn-install (version mới — non-interactive)

---

## 1. Kết nối VPS

```bash
ssh root@<VPS_IP>
```

---

## 2. Tải script

```bash
wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
```

---

## 3. Cài đặt OpenVPN + tạo client đầu tiên

```bash
bash openvpn-install.sh install \
  --endpoint <VPS_IP> \
  --port 1194 \
  --protocol udp \
  --dns google \
  --cipher AES-256-GCM \
  --client senvpn-client-1
```

Thay `<VPS_IP>` bằng IP thật của VPS (ví dụ: `45.95.186.195`).

Sau khi xong sẽ thấy:
```
[OK] The configuration file has been written to /root/senvpn-client-1.ovpn.
```

---

## 4. Lấy nội dung file .ovpn

```bash
cat /root/senvpn-client-1.ovpn
```

Copy toàn bộ nội dung → paste vào **Admin panel → Servers → Thêm server → ovpnConfig**.

---

## 5. Tạo thêm client (thêm server trong app)

```bash
bash openvpn-install.sh client add --client senvpn-client-2
cat /root/senvpn-client-2.ovpn
```

Mỗi file `.ovpn` = 1 server entry trong Admin panel.

---

## 6. Xem danh sách client hiện có

```bash
bash openvpn-install.sh client list
```

---

## 7. Thu hồi client

```bash
bash openvpn-install.sh client revoke --client senvpn-client-1
```

---

## 8. Kiểm tra OpenVPN đang chạy

```bash
systemctl status openvpn-server@server
```

---

## 9. Xem client đang kết nối

```bash
cat /var/log/openvpn/status.log
```

---

## 10. Gỡ cài đặt hoàn toàn

```bash
bash openvpn-install.sh uninstall
```

---

## Lưu ý

- Mỗi VPS có thể tạo nhiều file `.ovpn` (nhiều server entry trong app)
- Không dùng chung 1 file `.ovpn` cho nhiều server — tạo client riêng cho mỗi cái
- Sau khi thêm server vào Admin, bật **isActive = true** và kiểm tra ping
- Nếu cần allow port firewall thủ công:
  ```bash
  ufw allow 1194/udp
  ufw allow OpenSSH
  ufw enable
  ```
