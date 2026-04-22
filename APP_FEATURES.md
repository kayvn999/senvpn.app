# SEN VPN — Tài liệu tính năng ứng dụng
> Dùng để khai báo Google Play Store & Apple App Store  
> Cập nhật mỗi khi nâng cấp tính năng

---

## Thông tin ứng dụng

| Trường | Nội dung |
|--------|----------|
| **Tên app** | SEN VPN |
| **Package** | (Android) / Bundle ID (iOS) |
| **Phiên bản hiện tại** | 1.0.0 (Build 1) |
| **Ngôn ngữ** | Flutter (Dart) |
| **Backend** | Next.js + Firebase + VPS |
| **URL Admin** | https://lephap.io.vn |

---

## Mô tả ngắn (Short Description — 80 ký tự)
> VPN nhanh, bảo mật, miễn phí — Kết nối toàn cầu an toàn với SEN VPN.

## Mô tả đầy đủ (Full Description)
> SEN VPN bảo vệ quyền riêng tư của bạn với mã hóa AES-256, ẩn địa chỉ IP và kết nối tốc độ cao tới 50+ máy chủ toàn cầu. Dùng miễn phí không giới hạn thời gian, nâng cấp VIP để mở khóa tất cả máy chủ và tính năng nâng cao.

---

## Tính năng theo phiên bản

---

### v1.0.0 — Ra mắt lần đầu (19/04/2026)

#### VPN Core
- [x] Kết nối VPN qua giao thức **OpenVPN**
- [x] Tích hợp **VPNGate** — 200+ máy chủ miễn phí từ cộng đồng toàn cầu
- [x] Tự động chọn máy chủ tốt nhất theo ping
- [x] Hiển thị tốc độ download/upload và thời gian kết nối realtime
- [x] Hiển thị IP ảo sau khi kết nối
- [x] Trạng thái kết nối: Disconnected → Connecting → Connected → Error

#### Máy chủ
- [x] 50+ máy chủ tại 30+ quốc gia (Free tier)
- [x] Hiển thị cờ quốc gia, ping, tải server (load %), tốc độ
- [x] Nhóm server theo quốc gia
- [x] Tìm kiếm server theo tên/quốc gia
- [x] Tab **Free** và tab **VIP** riêng biệt
- [x] Free: tối đa 5 server/quốc gia, 30 quốc gia
- [x] VIP: toàn bộ server không giới hạn

#### Gói VIP / Subscription
| Gói | Giá | Thời hạn | Tính năng thêm |
|-----|-----|----------|----------------|
| Gói tuần | 29.000 VND | 7 ngày | Tất cả server VIP, không giới hạn data, tốc độ cao |
| Gói tháng ⭐ | 79.000 VND | 30 ngày | + Kill Switch, DNS bảo mật |
| Gói năm | 599.000 VND | 365 ngày | + Ưu tiên hỗ trợ |

- [x] Giá hiển thị đầy đủ với đơn vị tiền tệ (79.000 VND)
- [x] Đánh dấu "PHỔ BIẾN" cho gói tháng
- [x] Gói lấy từ Admin Panel realtime (không hardcode)
- [ ] Thanh toán Google Play / Apple IAP (sẽ tích hợp sau)

#### Bảo mật & Quyền riêng tư
- [x] Mã hóa **AES-256**
- [x] **Kill Switch** (VIP) — Ngắt internet nếu VPN bị mất kết nối
- [x] **DNS Leak Protection** (VIP) — Bảo vệ DNS không bị rò rỉ
- [x] **Biometric Lock** — Khóa app bằng vân tay / Face ID
- [x] Không lưu log hoạt động người dùng (No-logs policy)

#### Tài khoản & Nhận dạng
- [x] **Tự động đăng nhập ẩn danh** khi mở app lần đầu (không cần đăng ký)
- [x] Đăng nhập **Google**
- [x] Đăng nhập/Đăng ký **Email + Password** (có xác thực email)
- [x] Mỗi thiết bị có UID riêng tự động — Admin theo dõi được từ đầu
- [x] Khi đăng nhập sau → giữ nguyên lịch sử

#### Cài đặt
- [x] **Tự động kết nối** khi mở app (Free)
- [x] Kill Switch toggle (VIP)
- [x] DNS Leak Protection toggle (VIP)
- [x] Thông báo kết nối VPN
- [x] Khóa sinh trắc học

#### Thông báo
- [x] **Push Notification** qua Firebase Cloud Messaging
- [x] Gửi từ Admin Panel đến: Tất cả / Chỉ VIP / Chỉ Free
- [x] Tự động subscribe topic theo tier (vip_users / free_users / all_users)

#### Cập nhật bắt buộc (Force Update)
- [x] Kiểm tra phiên bản tại Splash Screen
- [x] So sánh version hiện tại với `minVersion` trên server
- [x] Hiển thị dialog bắt buộc cập nhật nếu version quá cũ
- [x] Kèm release notes và link tải

#### Onboarding
- [x] 4 màn hình giới thiệu tính năng (lần đầu mở app)
- [x] Có nút Skip để bỏ qua

#### Crash & Analytics
- [x] **Firebase Crashlytics** — Báo cáo crash tự động
- [x] **Firebase Analytics** — Theo dõi hành vi người dùng
- [x] Ghi log kết nối VPN (server, thời gian, data dùng)

---

## Admin Panel — https://lephap.io.vn

### Tính năng quản trị

| Trang | Tính năng |
|-------|-----------|
| **Tổng quan** | Thống kê tổng: users, VIP, server, doanh thu tháng, chế độ bảo trì |
| **Máy chủ VPN** | Thêm/sửa/xóa/bật-tắt server. Lưu local JSON trên VPS |
| **Gói VIP** | Thêm/sửa/xóa gói, toggle phổ biến, nhiều loại tiền tệ |
| **Người dùng** | Xem danh sách, tìm kiếm, cấp/thu hồi VIP thủ công |
| **Thống kê** | Biểu đồ đăng ký mới 7 ngày, kết nối 7 ngày, phân bố VIP/Free |
| **Doanh thu** | Tổng doanh thu, VIP đang hoạt động, danh sách VIP |
| **Thông báo** | Soạn và gửi push notification đến all/VIP/Free |
| **Lịch sử** | Log kết nối VPN của từng người dùng |
| **Phiên bản App** | Quản lý version, bật force update, release notes |
| **Cài đặt** | Giới hạn data free, max connections, blocked countries, maintenance mode |

### Kiến trúc lưu trữ
- **Local JSON** (VPS `/var/www/senvpn-admin/data/`): servers, plans, settings
- **Firebase Firestore**: users, connection logs, notifications, app_version
- **Firebase Admin SDK**: Đọc/ghi Firestore phía server (không bị chặn security rules)

---

## Kỹ thuật

### Flutter Dependencies chính
| Package | Mục đích |
|---------|----------|
| `openvpn_flutter` | Native OpenVPN client |
| `firebase_auth` | Xác thực người dùng |
| `google_sign_in` | Đăng nhập Google |
| `cloud_firestore` | Database realtime |
| `firebase_messaging` | Push notification |
| `firebase_crashlytics` | Báo cáo crash |
| `firebase_analytics` | Phân tích hành vi |
| `flutter_riverpod` | State management |
| `go_router` | Điều hướng màn hình |
| `in_app_purchase` | Mua hàng trong app |
| `purchases_flutter` | RevenueCat SDK |
| `google_mobile_ads` | AdMob quảng cáo |
| `local_auth` | Xác thực sinh trắc học |
| `shared_preferences` | Lưu cài đặt local |

### Quyền truy cập cần khai báo (Permissions)

**Android:**
- `INTERNET` — Kết nối mạng
- `FOREGROUND_SERVICE` — VPN chạy nền
- `BIND_VPN_SERVICE` — Dịch vụ VPN
- `USE_BIOMETRIC` / `USE_FINGERPRINT` — Xác thực sinh trắc
- `RECEIVE_BOOT_COMPLETED` — Tự động kết nối khi khởi động
- `POST_NOTIFICATIONS` — Gửi thông báo

**iOS:**
- `NSFaceIDUsageDescription` — Face ID
- Network Extension — VPN

---

## Changelog

### v1.0.0 (19/04/2026)
- Ra mắt ứng dụng
- VPN qua OpenVPN + VPNGate (200+ server miễn phí)
- 3 gói VIP: tuần/tháng/năm lấy từ Admin Panel
- Đăng nhập Google, Email, ẩn danh tự động
- Kill Switch, DNS Leak Protection (VIP)
- Push notification từ admin
- Force update từ admin
- Admin Panel đầy đủ: server, plans, users, analytics, revenue, notifications

---

## Kế hoạch tính năng tiếp theo

- [ ] Thanh toán Google Play Billing
- [ ] Thanh toán Apple In-App Purchase
- [ ] WireGuard protocol (nhanh hơn OpenVPN)
- [ ] Widget màn hình chính (Android/iOS)
- [ ] Chặn quảng cáo ở cấp độ DNS
- [ ] Chia sẻ kết nối (hotspot qua VPN)
- [ ] Hỗ trợ đa ngôn ngữ (EN, VI, JP, KR)
- [ ] Dark mode
- [ ] Thống kê data sử dụng theo ngày/tuần/tháng
