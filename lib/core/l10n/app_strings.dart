abstract class AppStrings {
  const AppStrings();

  String get langCode;

  // ── Common ─────────────────────────────────────────────────────────────────
  String get ok;
  String get cancel;
  String get save;
  String get close;
  String get retry;
  String get loading;
  String get error;
  String get skip;
  String get next;
  String get getStarted;
  String get vip;
  String get free;

  // ── Home ───────────────────────────────────────────────────────────────────
  String get homeTitle;
  String get connectButton;
  String get disconnectButton;
  String get connecting;
  String get connected;
  String get disconnecting;
  String get disconnected;
  String get statusConnected;
  String get statusDisconnected;
  String get statusConnecting;
  String get noServerSelected;
  String get selectServerHint;
  String get upgradeVipBanner;
  String get viewButton;
  String get freeUser;
  String get vipUser;
  String get dataUsed;
  String get dataRemaining;
  String get unlimited;

  // ── Servers ────────────────────────────────────────────────────────────────
  String get chooseServer;
  String get searchCountry;
  String get serversTab; // "Servers" tab label
  String get freeTab;
  String get vipTab;
  String get serverCount; // "{n} server" — use with format
  String get noServers;
  String get loadingServers;

  // ── VIP ────────────────────────────────────────────────────────────────────
  String get vipScreenTitle;
  String get vipActiveTitle;
  String get vipActiveSubtitle;
  String get vipExpiry;
  String get vipDaysLeft; // "{n} ngày"
  String get vipPlanActive;
  String get choosePlan;
  String get purchaseButton; // "Bắt đầu dùng {plan}"
  String get autoRenew;
  String get cancelAnytime;
  String get termsPrivacy;
  String get yourFeatures;
  // Feature labels
  String get feat50Servers;
  String get featUnlimited;
  String get featHighSpeed;
  String get featKillSwitch;
  String get featAdBlock;

  // ── Settings ───────────────────────────────────────────────────────────────
  String get settingsTitle;
  String get sectionVpn;
  String get sectionSecurity;
  String get sectionActivation;
  String get sectionAbout;
  String get sectionLanguage;
  String get autoConnect;
  String get autoConnectSub;
  String get killSwitch;
  String get killSwitchSub;
  String get dnsLeak;
  String get dnsLeakSub;
  String get biometric;
  String get biometricSub;
  String get notifications;
  String get notificationsSub;
  String get rateApp;
  String get shareApp;
  String get privacyPolicy;
  String get termsOfService;
  String get appVersion;
  String get activationTitle;
  String get activationSubtitle;
  String get activationHint;
  String get activateButton;
  String get activationSuccess;
  String get activationConnecting;
  String get language;
  String get languageVi;
  String get languageEn;

  // ── Onboarding ─────────────────────────────────────────────────────────────
  String get ob1Title;
  String get ob1Sub;
  String get ob2Title;
  String get ob2Sub;
  String get ob3Title;
  String get ob3Sub;
  String get ob4Title;
  String get ob4Sub;

  // ── Language picker ────────────────────────────────────────────────────────
  String get langPickerTitle;
  String get langPickerSub;
  String get continueButton;

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  String get navHome;
  String get navServers;
  String get navSettings;
}
