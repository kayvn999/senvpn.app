import 'app_strings.dart';

class EnStrings extends AppStrings {
  const EnStrings();

  @override String get langCode => 'en';

  // Common
  @override String get ok => 'OK';
  @override String get cancel => 'Cancel';
  @override String get save => 'Save';
  @override String get close => 'Close';
  @override String get retry => 'Retry';
  @override String get loading => 'Loading...';
  @override String get error => 'Error';
  @override String get skip => 'Skip';
  @override String get next => 'Next';
  @override String get getStarted => 'Get Started';
  @override String get vip => 'VIP';
  @override String get free => 'Free';

  // Home
  @override String get homeTitle => 'SEN VPN';
  @override String get connectButton => 'Connect';
  @override String get disconnectButton => 'Disconnect';
  @override String get connecting => 'Connecting';
  @override String get connected => 'Connected';
  @override String get disconnecting => 'Disconnecting';
  @override String get disconnected => 'Not Connected';
  @override String get statusConnected => 'Connected';
  @override String get statusDisconnected => 'Not Connected';
  @override String get statusConnecting => 'Connecting...';
  @override String get noServerSelected => 'No server selected';
  @override String get selectServerHint => 'Select a server to connect';
  @override String get upgradeVipBanner => '⭐  Upgrade to VIP';
  @override String get viewButton => 'View';
  @override String get freeUser => 'Free Account';
  @override String get vipUser => 'VIP Account';
  @override String get dataUsed => 'Used';
  @override String get dataRemaining => 'Remaining';
  @override String get unlimited => 'Unlimited';

  // Servers
  @override String get chooseServer => 'Choose Server';
  @override String get searchCountry => 'Search country...';
  @override String get serversTab => 'Servers';
  @override String get freeTab => 'Free';
  @override String get vipTab => 'VIP';
  @override String get serverCount => 'server';
  @override String get noServers => 'No servers available';
  @override String get loadingServers => 'Loading servers...';

  // VIP
  @override String get vipScreenTitle => 'SEN VPN Premium';
  @override String get vipActiveTitle => 'You are on VIP';
  @override String get vipActiveSubtitle => 'Enjoy all Premium features';
  @override String get vipExpiry => 'Expires:';
  @override String get vipDaysLeft => 'days';
  @override String get vipPlanActive => 'VIP Plan Active';
  @override String get choosePlan => 'Choose a plan';
  @override String get purchaseButton => 'Get';
  @override String get autoRenew => 'Auto-renews · Cancel anytime';
  @override String get cancelAnytime => 'Cancel anytime';
  @override String get termsPrivacy => 'Terms of Service  ·  Privacy Policy';
  @override String get yourFeatures => 'YOUR FEATURES';
  @override String get feat50Servers => 'Global servers';
  @override String get featUnlimited => 'Unlimited bandwidth';
  @override String get featHighSpeed => 'High-speed connection';
  @override String get featKillSwitch => 'Kill Switch & DNS security';
  @override String get featAdBlock => 'IP address masking';

  // Settings
  @override String get settingsTitle => 'Settings';
  @override String get sectionVpn => 'VPN Settings';
  @override String get sectionSecurity => 'Security';
  @override String get sectionActivation => 'VIP Activation Key';
  @override String get sectionAbout => 'About';
  @override String get sectionLanguage => 'Language';
  @override String get autoConnect => 'Auto Connect';
  @override String get autoConnectSub => 'Connect VPN on app launch';
  @override String get killSwitch => 'Kill Switch';
  @override String get killSwitchSub => 'Block internet when VPN disconnects';
  @override String get dnsLeak => 'DNS Leak Protection';
  @override String get dnsLeakSub => 'Protect against DNS leaks';
  @override String get biometric => 'Biometric Lock';
  @override String get biometricSub => 'Use fingerprint / Face ID to unlock';
  @override String get notifications => 'Notifications';
  @override String get notificationsSub => 'Receive VPN connection notifications';
  @override String get rateApp => 'Rate App';
  @override String get shareApp => 'Share App';
  @override String get privacyPolicy => 'Privacy Policy';
  @override String get termsOfService => 'Terms of Service';
  @override String get appVersion => 'Version';
  @override String get activationTitle => 'Enter activation code';
  @override String get activationSubtitle => 'Enter an activation key to upgrade to VIP';
  @override String get activationHint => 'SENV-XXXX-XXXX-XXXX';
  @override String get activateButton => 'Activate';
  @override String get activationSuccess => 'Activated! VIP is being applied...';
  @override String get activationConnecting => 'Cannot connect to server.';
  @override String get language => 'Language';
  @override String get languageVi => 'Tiếng Việt';
  @override String get languageEn => 'English';

  // Onboarding
  @override String get ob1Title => 'Protect Your\nPrivacy';
  @override String get ob1Sub => 'Encrypt your network traffic\nto keep your personal data safe online.';
  @override String get ob2Title => 'Secure\nConnection';
  @override String get ob2Sub => 'Powered by OpenVPN protocol\nfor private and reliable browsing.';
  @override String get ob3Title => 'Global\nServers';
  @override String get ob3Sub => 'Connect to servers across multiple countries\nand find the best connection for you.';
  @override String get ob4Title => 'Get Started\nToday';
  @override String get ob4Sub => 'Try for free or upgrade to VIP\nto unlock all premium features.';

  // Language picker
  @override String get langPickerTitle => 'Choose Language';
  @override String get langPickerSub => 'You can change this in Settings later';
  @override String get continueButton => 'Continue';

  @override String get navHome => 'Home';
  @override String get navServers => 'Servers';
  @override String get navSettings => 'Settings';
}
