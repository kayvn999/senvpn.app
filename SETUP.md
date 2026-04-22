# SecureVPN - Setup Guide

## Bước 1: Tạo Flutter project skeleton
```bash
cd c:\Users\maste\app\appso1
flutter create . --project-name appso1 --org com.securevpn --platforms android,ios
```
> Lưu ý: Chạy lệnh này sẽ tạo các file còn thiếu (như Runner.xcworkspace cho iOS), 
> nhưng sẽ không ghi đè các file đã tồn tại (lib/, android/app/build.gradle, v.v.)

## Bước 2: Cài packages
```bash
flutter pub get
```

## Bước 3: Cấu hình Firebase
1. Tạo project trên https://console.firebase.google.com
2. Thêm Android app với package: `com.securevpn.app`
3. Tải `google-services.json` → đặt vào `android/app/`
4. Thêm iOS app với bundle ID: `com.securevpn.app`
5. Tải `GoogleService-Info.plist` → đặt vào `ios/Runner/`
6. Bật Authentication (Google, Email/Password)
7. Tạo Firestore database

## Bước 4: Cấu hình Firestore (tạo collection servers)
Thêm document mẫu vào collection `servers`:
```json
{
  "name": "Vietnam - Ho Chi Minh",
  "host": "hcm1.securevpn.app",
  "port": 1194,
  "protocol": "OpenVPN",
  "country": "Vietnam",
  "countryCode": "VN",
  "flag": "🇻🇳",
  "ping": 15,
  "load": 42,
  "isFree": true,
  "isVip": false,
  "isActive": true,
  "speedMbps": 50
}
```

## Bước 5: Cấu hình AdMob
1. Tạo tài khoản AdMob tại https://admob.google.com
2. Tạo app Android + iOS
3. Thay App ID trong:
   - `android/app/src/main/AndroidManifest.xml` (dòng `GAD_APPLICATION_ID`)
   - `ios/Runner/Info.plist` (dòng `GADApplicationIdentifier`)
4. Tạo ad units (Banner, Interstitial, Rewarded)
5. Cập nhật Ad Unit IDs trong `lib/core/constants/app_constants.dart`

## Bước 6: Setup RevenueCat (VIP purchases)
1. Tạo tài khoản tại https://www.revenuecat.com
2. Tạo các products trong Google Play Console:
   - `securevpn_weekly` - 29,000 VND
   - `securevpn_monthly` - 79,000 VND  
   - `securevpn_yearly` - 599,000 VND
3. Thay API keys trong `lib/core/constants/app_constants.dart`

## Bước 7: Chạy ứng dụng
```bash
flutter run
```

## Cấu trúc thư mục
```
lib/
├── main.dart               # Entry point
├── app.dart                # App + Router
├── core/
│   ├── theme/              # Dark theme + colors
│   ├── constants/          # App constants, AdMob IDs
│   ├── vpn/               # VPN service (OpenVPN)
│   ├── firebase/          # Auth, Firestore, Remote Config
│   └── ads/               # AdMob service
├── models/                # Data models
├── providers/             # Riverpod state
└── features/
    ├── splash/            # Splash screen
    ├── onboarding/        # 4-page onboarding
    ├── auth/              # Login + Register
    ├── home/              # Main VPN screen
    ├── servers/           # Server list
    ├── vip/               # VIP upgrade
    └── settings/          # App settings
```

## VPN Servers miễn phí (tùy chọn)
Để lấy server OpenVPN miễn phí từ VPNGate:
```
URL: http://www.vpngate.net/api/iphone/
Format: CSV với ovpn configs encoded
```

## Notes
- App sử dụng test Ad IDs của Google - cần thay bằng IDs thật trước khi publish
- Firebase cần được cấu hình trước khi chạy
- Với demo mode (không có Firebase), app vẫn hiển thị UI với demo data
