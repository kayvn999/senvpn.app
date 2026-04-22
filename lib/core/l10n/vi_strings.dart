import 'app_strings.dart';

class ViStrings extends AppStrings {
  const ViStrings();

  @override String get langCode => 'vi';

  // Common
  @override String get ok => 'OK';
  @override String get cancel => 'Hủy';
  @override String get save => 'Lưu';
  @override String get close => 'Đóng';
  @override String get retry => 'Thử lại';
  @override String get loading => 'Đang tải...';
  @override String get error => 'Lỗi';
  @override String get skip => 'Bỏ qua';
  @override String get next => 'Tiếp theo';
  @override String get getStarted => 'Bắt đầu ngay';
  @override String get vip => 'VIP';
  @override String get free => 'Miễn phí';

  // Home
  @override String get homeTitle => 'SEN VPN';
  @override String get connectButton => 'Kết nối';
  @override String get disconnectButton => 'Ngắt kết nối';
  @override String get connecting => 'Đang kết nối';
  @override String get connected => 'Đã kết nối';
  @override String get disconnecting => 'Đang ngắt';
  @override String get disconnected => 'Chưa kết nối';
  @override String get statusConnected => 'Đã kết nối';
  @override String get statusDisconnected => 'Chưa kết nối';
  @override String get statusConnecting => 'Đang kết nối...';
  @override String get noServerSelected => 'Chưa chọn máy chủ';
  @override String get selectServerHint => 'Chọn máy chủ để kết nối';
  @override String get upgradeVipBanner => '⭐  Nâng cấp VIP';
  @override String get viewButton => 'Xem';
  @override String get freeUser => 'Tài khoản Free';
  @override String get vipUser => 'Tài khoản VIP';
  @override String get dataUsed => 'Đã dùng';
  @override String get dataRemaining => 'Còn lại';
  @override String get unlimited => 'Không giới hạn';

  // Servers
  @override String get chooseServer => 'Chọn máy chủ';
  @override String get searchCountry => 'Tìm quốc gia...';
  @override String get serversTab => 'Máy chủ';
  @override String get freeTab => 'Miễn phí';
  @override String get vipTab => 'VIP';
  @override String get serverCount => 'server';
  @override String get noServers => 'Không có máy chủ nào';
  @override String get loadingServers => 'Đang tải máy chủ...';

  // VIP
  @override String get vipScreenTitle => 'SEN VPN Premium';
  @override String get vipActiveTitle => 'Bạn đang dùng VIP';
  @override String get vipActiveSubtitle => 'Tận hưởng đầy đủ tính năng Premium';
  @override String get vipExpiry => 'Hết hạn:';
  @override String get vipDaysLeft => 'ngày';
  @override String get vipPlanActive => 'Gói VIP đang hoạt động';
  @override String get choosePlan => 'Chọn gói phù hợp';
  @override String get purchaseButton => 'Bắt đầu dùng';
  @override String get autoRenew => 'Tự động gia hạn · Hủy bất kỳ lúc nào';
  @override String get cancelAnytime => 'Hủy bất kỳ lúc nào';
  @override String get termsPrivacy => 'Điều khoản dịch vụ  ·  Chính sách bảo mật';
  @override String get yourFeatures => 'TÍNH NĂNG CỦA BẠN';
  @override String get feat50Servers => 'Máy chủ toàn cầu';
  @override String get featUnlimited => 'Không giới hạn băng thông';
  @override String get featHighSpeed => 'Kết nối tốc độ cao';
  @override String get featKillSwitch => 'Kill Switch & DNS bảo mật';
  @override String get featAdBlock => 'Ẩn địa chỉ IP';

  // Settings
  @override String get settingsTitle => 'Cài đặt';
  @override String get sectionVpn => 'Cài đặt VPN';
  @override String get sectionSecurity => 'Bảo mật';
  @override String get sectionActivation => 'Mã kích hoạt VIP';
  @override String get sectionAbout => 'Thông tin';
  @override String get sectionLanguage => 'Ngôn ngữ';
  @override String get autoConnect => 'Tự động kết nối';
  @override String get autoConnectSub => 'Kết nối VPN khi khởi động ứng dụng';
  @override String get killSwitch => 'Kill Switch';
  @override String get killSwitchSub => 'Chặn internet khi VPN bị ngắt';
  @override String get dnsLeak => 'DNS Leak Protection';
  @override String get dnsLeakSub => 'Bảo vệ rò rỉ DNS của bạn';
  @override String get biometric => 'Khóa sinh trắc học';
  @override String get biometricSub => 'Dùng vân tay / Face ID để mở khóa';
  @override String get notifications => 'Thông báo';
  @override String get notificationsSub => 'Nhận thông báo kết nối VPN';
  @override String get rateApp => 'Đánh giá ứng dụng';
  @override String get shareApp => 'Chia sẻ ứng dụng';
  @override String get privacyPolicy => 'Chính sách bảo mật';
  @override String get termsOfService => 'Điều khoản dịch vụ';
  @override String get appVersion => 'Phiên bản';
  @override String get activationTitle => 'Nhập mã kích hoạt để nâng cấp VIP';
  @override String get activationSubtitle => 'Nhập mã kích hoạt để nâng cấp VIP';
  @override String get activationHint => 'SENV-XXXX-XXXX-XXXX';
  @override String get activateButton => 'Kích hoạt';
  @override String get activationSuccess => 'Kích hoạt thành công! VIP đang được cập nhật...';
  @override String get activationConnecting => 'Không thể kết nối máy chủ.';
  @override String get language => 'Ngôn ngữ';
  @override String get languageVi => 'Tiếng Việt';
  @override String get languageEn => 'English';

  // Onboarding
  @override String get ob1Title => 'Bảo vệ\nquyền riêng tư';
  @override String get ob1Sub => 'Mã hóa lưu lượng mạng,\ngiúp bảo vệ thông tin cá nhân khi trực tuyến.';
  @override String get ob2Title => 'Kết nối\nan toàn';
  @override String get ob2Sub => 'Sử dụng giao thức OpenVPN bảo mật,\ngiúp duyệt web riêng tư và ổn định hơn.';
  @override String get ob3Title => 'Nhiều Server\nToàn cầu';
  @override String get ob3Sub => 'Kết nối đến server ở nhiều quốc gia,\nluôn tìm thấy kết nối phù hợp nhất.';
  @override String get ob4Title => 'Bắt đầu\nngay hôm nay';
  @override String get ob4Sub => 'Trải nghiệm miễn phí hoặc nâng cấp\nlên VIP để mở khóa toàn bộ tính năng.';

  // Language picker
  @override String get langPickerTitle => 'Chọn ngôn ngữ';
  @override String get langPickerSub => 'Bạn có thể thay đổi trong Cài đặt sau này';
  @override String get continueButton => 'Tiếp tục';

  @override String get navHome => 'Trang chủ';
  @override String get navServers => 'Máy chủ';
  @override String get navSettings => 'Cài đặt';
}
