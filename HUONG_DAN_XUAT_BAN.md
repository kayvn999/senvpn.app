# Hướng dẫn xuất bản SEN VPN lên CH Play & App Store

---

## PHẦN 1 — REVENUECAT (Thanh toán In-App)

### Bước 1: Kết nối app Android + iOS vào RevenueCat

1. Vào RC Dashboard → **Apps & providers → Configurations**
2. Bấm **+ New** → chọn **Google Play Store**
   - Điền Package name: `com.senvpn.app`
   - Kết nối với Google Play Console theo hướng dẫn RC
3. Bấm **+ New** lần nữa → chọn **App Store**
   - Điền Bundle ID: `com.senvpn.app` (hoặc ID bạn đặt trong Xcode)
   - Kết nối với App Store Connect theo hướng dẫn RC
4. Sau khi kết nối xong, vào **Apps & providers → API Keys**
   - RC sẽ tự tạo key riêng cho từng platform (Android + iOS)
   - Copy từng key và điền vào `lib/core/constants/app_constants.dart`:
     - `revenueCatApiKeyAndroid` = key của Google Play app
     - `revenueCatApiKeyIos` = key của App Store app

> **Hiện tại:** đang dùng key test `test_tEbnQnEWWyQGGNuharEarYkbVOj` (Test Store).
> Key này chỉ dùng để test flow mua hàng, KHÔNG dùng khi lên production.
> Khi lên production: thay bằng key thật của từng platform rồi build lại app.

---

### Bước 2: Tạo sản phẩm trong Google Play Console

1. Vào [play.google.com/console](https://play.google.com/console)
2. Chọn app SEN VPN → **Kiếm tiền → Sản phẩm → Gói đăng ký**
3. Tạo 3 gói đăng ký với đúng ID này (bắt buộc phải khớp):

| Product ID | Tên hiển thị | Giá | Chu kỳ |
|---|---|---|---|
| `securevpn_weekly` | SEN VPN Gói Tuần | 29.000đ | 1 tuần |
| `securevpn_monthly` | SEN VPN Gói Tháng | 79.000đ | 1 tháng |
| `securevpn_yearly` | SEN VPN Gói Năm | 599.000đ | 1 năm |

---

### Bước 3: Tạo sản phẩm trong App Store Connect (iOS)

1. Vào [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Chọn app SEN VPN → **In-App Purchases → Manage**
3. Tạo 3 **Auto-Renewable Subscription** với đúng ID này:

| Product ID | Tên hiển thị | Giá | Chu kỳ |
|---|---|---|---|
| `securevpn_weekly` | SEN VPN Weekly | $1.99 | 1 tuần |
| `securevpn_monthly` | SEN VPN Monthly | $3.99 | 1 tháng |
| `securevpn_yearly` | SEN VPN Yearly | $29.99 | 1 năm |

> Giá USD chỉ là ví dụ, bạn tự chỉnh theo chiến lược giá.

---

### Bước 4: Kết nối sản phẩm vào RevenueCat

1. Vào RC Dashboard → **Products**
2. Bấm **+ New** → chọn platform (Google Play / App Store) → nhập Product ID → Save
3. Làm cho cả 6 sản phẩm (3 Android + 3 iOS)

---

### Bước 5: Tạo Offering trong RevenueCat

1. Vào RC Dashboard → **Offerings**
2. Bấm vào **Default** offering
3. Trong Default Offering, bấm **+ Add package** 3 lần:

| Package identifier | Type | Gắn với product |
|---|---|---|
| `weekly` | Weekly | `securevpn_weekly` |
| `monthly` | Monthly | `securevpn_monthly` |
| `yearly` | Annual | `securevpn_yearly` |

---

### Bước 6: Cấu hình Webhook (để VIP tự động kích hoạt)

1. Vào RC Dashboard → **Integrations → Webhooks**
2. Bấm **+ Add webhook**
3. Điền:
   - **URL**: `https://lephap.io.vn/api/webhook/revenuecat`
   - **Events**: chọn tất cả (hoặc ít nhất: INITIAL_PURCHASE, RENEWAL, CANCELLATION, EXPIRATION)
4. Bấm **Save** → RC sẽ sinh ra **Authorization secret**
5. Copy secret đó
6. Vào **Admin CPanel** (`https://lephap.io.vn/admin`) → **Cài đặt** → mục **In-App Purchase (RevenueCat)**
7. Dán secret vào ô **Webhook Secret** → bấm **Lưu cài đặt**

> Sau khi làm xong bước này: khi người dùng mua hàng thành công → RC gọi webhook → VPS tự cấp VIP → app nhận trong vòng 30 giây.

---

## PHẦN 2 — GOOGLE ADMOB (Quảng cáo)

### App ID đã cài sẵn trong app:
- Android: `ca-app-pub-9958247766651079~2543356751`
- iOS: `ca-app-pub-9958247766651079~5873287169`

### Cách quản lý Ad Unit ID:

1. Vào [admob.google.com](https://admob.google.com)
2. Tạo Ad Units cho từng loại (Banner, Interstitial, Rewarded) cho cả Android và iOS
3. Copy các Ad Unit ID
4. Vào **Admin CPanel → Cài đặt → Quảng cáo (AdMob)**
5. Dán ID vào các ô tương ứng → bật toggle **Bật quảng cáo** → Lưu
6. App sẽ nhận ID mới trong vòng 60 giây, KHÔNG cần build lại app

---

## PHẦN 3 — BUILD APP

### Android (APK / AAB cho CH Play):

```bash
# Build AAB để upload lên CH Play
flutter build appbundle --release

# File output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (cho App Store):

```bash
# Build iOS
flutter build ios --release

# Sau đó mở Xcode → Product → Archive → Distribute App
```

### Trước khi build — checklist:

- [ ] Điền RC API key thật vào `lib/core/constants/app_constants.dart`
- [ ] Đã tạo sản phẩm trong Play Console / App Store Connect
- [ ] Đã tạo Offering trong RC dashboard
- [ ] Đã cấu hình webhook RC → Admin CPanel
- [ ] Đã bật quảng cáo và điền Ad Unit ID thật trong Admin CPanel

---

## PHẦN 4 — THÔNG TIN TÀI KHOẢN & SERVER

| Mục | Thông tin |
|---|---|
| VPS IP | 160.22.170.223 |
| Admin CPanel | https://lephap.io.vn/admin |
| API config URL | https://lephap.io.vn/api/config |
| Webhook RC URL | https://lephap.io.vn/api/webhook/revenuecat |
| RC Project | SEN VPN (app.revenuecat.com) |
| AdMob Android App ID | ca-app-pub-9958247766651079~2543356751 |
| AdMob iOS App ID | ca-app-pub-9958247766651079~5873287169 |
