'use client';

import { useEffect, useState } from 'react';
import type { AppSettings } from '@/lib/local-store';

const ALL_COUNTRIES = [
  { code: 'VN', name: 'Việt Nam' }, { code: 'US', name: 'Hoa Kỳ' },
  { code: 'JP', name: 'Nhật Bản' }, { code: 'KR', name: 'Hàn Quốc' },
  { code: 'SG', name: 'Singapore' }, { code: 'DE', name: 'Đức' },
  { code: 'FR', name: 'Pháp' }, { code: 'GB', name: 'Anh' },
  { code: 'CA', name: 'Canada' }, { code: 'AU', name: 'Úc' },
  { code: 'NL', name: 'Hà Lan' }, { code: 'TH', name: 'Thái Lan' },
  { code: 'IN', name: 'Ấn Độ' }, { code: 'BR', name: 'Brazil' },
  { code: 'HK', name: 'Hong Kong' }, { code: 'TW', name: 'Đài Loan' },
  { code: 'MY', name: 'Malaysia' }, { code: 'ID', name: 'Indonesia' },
  { code: 'PH', name: 'Philippines' }, { code: 'CN', name: 'Trung Quốc' },
  { code: 'RU', name: 'Nga' }, { code: 'TR', name: 'Thổ Nhĩ Kỳ' },
  { code: 'SE', name: 'Thụy Điển' }, { code: 'CH', name: 'Thụy Sĩ' },
];

function flag(code: string) {
  try {
    const a = code.codePointAt(0)! - 65 + 0x1f1e6;
    const b = code.codePointAt(1)! - 65 + 0x1f1e6;
    return String.fromCodePoint(a) + String.fromCodePoint(b);
  } catch { return '🌍'; }
}

const defaultSettings: AppSettings = {
  freeDataLimitMB: 500,
  freeMaxConnections: 1,
  freeServersPerCountry: 3,
  allowedCountries: [],
  blockedCountries: [],
  maintenanceMode: false,
  maintenanceMessage: '',
  vpngateEnabled: true,
  vpngateMaxServers: 300,
  oneconnectEnabled: false,
  oneconnectApiKey: '',
  oneconnectFreeEnabled: true,
  oneconnectProEnabled: true,
  oneconnectAllowedCountries: [],
  storeUrl: '',
  shareText: 'Tải SEN VPN miễn phí tại: ',
  privacyPolicyUrl: '',
  termsUrl: '',
  adsEnabled: false,
  adIntervalSeconds: 180,
  bannerAdUnitAndroid: '',
  bannerAdUnitIos: '',
  interstitialAdUnitAndroid: '',
  interstitialAdUnitIos: '',
  rewardedAdUnitAndroid: '',
  rewardedAdUnitIos: '',
  revenueCatWebhookSecret: '',
};

export default function SettingsPage() {
  const [settings, setSettings] = useState<AppSettings>(defaultSettings);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch('/api/admin/settings');
        if (!res.ok) throw new Error(await res.text());
        setSettings(await res.json());
      } catch {
        setError('Không thể tải cài đặt.');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const handleSave = async () => {
    setSaving(true);
    setError('');
    try {
      const res = await fetch('/api/admin/settings', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(settings),
      });
      if (!res.ok) throw new Error(await res.text());
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch {
      setError('Lưu thất bại. Vui lòng thử lại.');
    } finally {
      setSaving(false);
    }
  };

  const toggleCountry = (code: string, list: 'allowed' | 'blocked') => {
    const field = list === 'allowed' ? 'allowedCountries' : 'blockedCountries';
    const otherField = list === 'allowed' ? 'blockedCountries' : 'allowedCountries';
    const current = settings[field];
    if (current.includes(code)) {
      setSettings(s => ({ ...s, [field]: current.filter(c => c !== code) }));
    } else {
      setSettings(s => ({
        ...s,
        [field]: [...current, code],
        [otherField]: s[otherField].filter(c => c !== code),
      }));
    }
  };

  const availableForAllowed = ALL_COUNTRIES.filter(c => !settings.allowedCountries.includes(c.code));
  const availableForBlocked = ALL_COUNTRIES.filter(
    c => !settings.blockedCountries.includes(c.code) && !settings.allowedCountries.includes(c.code)
  );

  if (loading) {
    return (
      <div className="space-y-4">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="bg-white rounded-2xl border border-gray-100 p-6 animate-pulse h-24" />
        ))}
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Cài đặt hệ thống</h1>
          <p className="text-sm text-gray-500 mt-1">Cấu hình giới hạn Free, VPNGate và chế độ bảo trì</p>
        </div>
        <button onClick={handleSave} disabled={saving}
          className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 text-white rounded-xl text-sm font-semibold hover:bg-indigo-700 disabled:opacity-60 transition-colors">
          {saving ? (
            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
          ) : (
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          )}
          {saving ? 'Đang lưu...' : 'Lưu cài đặt'}
        </button>
      </div>

      {error && <div className="mb-4 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">{error}</div>}
      {saved && (
        <div className="mb-4 bg-green-50 border border-green-200 rounded-xl px-4 py-3 text-sm text-green-700 flex items-center gap-2">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Đã lưu thành công! App Flutter sẽ nhận cài đặt mới ngay.
        </div>
      )}

      <div className="space-y-5">
        {/* Maintenance */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-4">Chế độ bảo trì</h2>
          <label className="flex items-center justify-between p-4 bg-gray-50 rounded-xl cursor-pointer">
            <div>
              <p className="font-medium text-gray-800">Bật chế độ bảo trì</p>
              <p className="text-sm text-gray-400 mt-0.5">Người dùng sẽ thấy thông báo khi mở app</p>
            </div>
            <button type="button" onClick={() => setSettings(s => ({ ...s, maintenanceMode: !s.maintenanceMode }))}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${settings.maintenanceMode ? 'bg-red-500' : 'bg-gray-300'}`}>
              <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${settings.maintenanceMode ? 'translate-x-6' : 'translate-x-1'}`} />
            </button>
          </label>
          {settings.maintenanceMode && (
            <div className="mt-3">
              <label className="block text-sm font-medium text-gray-700 mb-1">Thông báo bảo trì</label>
              <textarea rows={2} value={settings.maintenanceMessage ?? ''}
                onChange={e => setSettings(s => ({ ...s, maintenanceMessage: e.target.value }))}
                placeholder="Hệ thống đang bảo trì, vui lòng thử lại sau..."
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 resize-none" />
            </div>
          )}
        </div>

        {/* Free Limits */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-4">Giới hạn tài khoản Free</h2>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Giới hạn data (MB/ngày)</label>
              <input type="number" min={0} value={settings.freeDataLimitMB}
                onChange={e => setSettings(s => ({ ...s, freeDataLimitMB: Number(e.target.value) }))}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Số kết nối đồng thời</label>
              <input type="number" min={1} max={5} value={settings.freeMaxConnections}
                onChange={e => setSettings(s => ({ ...s, freeMaxConnections: Number(e.target.value) }))}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Server tối đa / quốc gia</label>
              <input type="number" min={1} max={20} value={settings.freeServersPerCountry}
                onChange={e => setSettings(s => ({ ...s, freeServersPerCountry: Number(e.target.value) }))}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
          </div>
        </div>

        {/* VPNGate */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-4">VPNGate</h2>
          <label className="flex items-center justify-between p-4 bg-gray-50 rounded-xl cursor-pointer mb-4">
            <div>
              <p className="font-medium text-gray-800">Bật VPNGate</p>
              <p className="text-sm text-gray-400 mt-0.5">Lấy server miễn phí từ vpngate.net cho tài khoản Free</p>
            </div>
            <button type="button" onClick={() => setSettings(s => ({ ...s, vpngateEnabled: !s.vpngateEnabled }))}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${settings.vpngateEnabled ? 'bg-indigo-500' : 'bg-gray-300'}`}>
              <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${settings.vpngateEnabled ? 'translate-x-6' : 'translate-x-1'}`} />
            </button>
          </label>
          {settings.vpngateEnabled && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Số server tối đa từ VPNGate</label>
              <input type="number" min={10} max={1000} step={10} value={settings.vpngateMaxServers}
                onChange={e => setSettings(s => ({ ...s, vpngateMaxServers: Number(e.target.value) }))}
                className="w-48 px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
          )}
        </div>

        {/* OneConnect */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-4">
          <h2 className="text-base font-bold text-gray-900 mb-2">OneConnect VPN</h2>
          <label className="flex items-center justify-between cursor-pointer">
            <div>
              <p className="text-sm font-medium text-gray-800">Bật OneConnect</p>
              <p className="text-sm text-gray-400 mt-0.5">Lấy server từ OneConnect API</p>
            </div>
            <button type="button" onClick={() => setSettings(s => ({ ...s, oneconnectEnabled: !s.oneconnectEnabled }))}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${settings.oneconnectEnabled ? 'bg-indigo-500' : 'bg-gray-300'}`}>
              <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${settings.oneconnectEnabled ? 'translate-x-6' : 'translate-x-1'}`} />
            </button>
          </label>
          {settings.oneconnectEnabled && (
            <div className="space-y-3">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">API Key</label>
                <input type="text" value={settings.oneconnectApiKey ?? ''}
                  onChange={e => setSettings(s => ({ ...s, oneconnectApiKey: e.target.value }))}
                  placeholder="API Key từ developer.oneconnect.top"
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
              </div>
              <div className="flex gap-6">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" checked={settings.oneconnectFreeEnabled ?? true}
                    onChange={e => setSettings(s => ({ ...s, oneconnectFreeEnabled: e.target.checked }))}
                    className="rounded" />
                  <span className="text-sm text-gray-700">Server Free</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input type="checkbox" checked={settings.oneconnectProEnabled ?? true}
                    onChange={e => setSettings(s => ({ ...s, oneconnectProEnabled: e.target.checked }))}
                    className="rounded" />
                  <span className="text-sm text-gray-700">Server Pro (VIP)</span>
                </label>
              </div>
            </div>
          )}
        </div>

        {/* App Info Links */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-4">Thông tin App (mục Cài đặt)</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Link Google Play Store (Đánh giá & Chia sẻ)</label>
              <input type="url" value={settings.storeUrl ?? ''}
                onChange={e => setSettings(s => ({ ...s, storeUrl: e.target.value }))}
                placeholder="https://play.google.com/store/apps/details?id=..."
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nội dung chia sẻ (Chia sẻ ứng dụng)</label>
              <input type="text" value={settings.shareText ?? ''}
                onChange={e => setSettings(s => ({ ...s, shareText: e.target.value }))}
                placeholder="Tải SEN VPN miễn phí tại: "
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
              <p className="text-xs text-gray-400 mt-1">Link Store sẽ tự ghép vào cuối nội dung này</p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Link Chính sách bảo mật</label>
              <input type="url" value={settings.privacyPolicyUrl ?? ''}
                onChange={e => setSettings(s => ({ ...s, privacyPolicyUrl: e.target.value }))}
                placeholder="https://..."
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Link Điều khoản dịch vụ</label>
              <input type="url" value={settings.termsUrl ?? ''}
                onChange={e => setSettings(s => ({ ...s, termsUrl: e.target.value }))}
                placeholder="https://..."
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
          </div>
        </div>

        {/* Ads */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-4">Quảng cáo (AdMob)</h2>
          <label className="flex items-center justify-between p-4 bg-gray-50 rounded-xl cursor-pointer mb-4">
            <div>
              <p className="font-medium text-gray-800">Bật quảng cáo</p>
              <p className="text-sm text-gray-400 mt-0.5">Hiển thị quảng cáo cho tài khoản Free</p>
            </div>
            <button type="button" onClick={() => setSettings(s => ({ ...s, adsEnabled: !s.adsEnabled }))}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${settings.adsEnabled ? 'bg-indigo-500' : 'bg-gray-300'}`}>
              <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${settings.adsEnabled ? 'translate-x-6' : 'translate-x-1'}`} />
            </button>
          </label>
          {settings.adsEnabled && (
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Khoảng cách giữa 2 lần hiện Interstitial (giây)</label>
                <input type="number" min={60} max={3600} value={settings.adIntervalSeconds ?? 180}
                  onChange={e => setSettings(s => ({ ...s, adIntervalSeconds: Number(e.target.value) }))}
                  className="w-32 px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">🟢 Banner Android</label>
                  <input type="text" value={settings.bannerAdUnitAndroid ?? ''}
                    onChange={e => setSettings(s => ({ ...s, bannerAdUnitAndroid: e.target.value }))}
                    placeholder="ca-app-pub-xxx/xxx"
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">🍎 Banner iOS</label>
                  <input type="text" value={settings.bannerAdUnitIos ?? ''}
                    onChange={e => setSettings(s => ({ ...s, bannerAdUnitIos: e.target.value }))}
                    placeholder="ca-app-pub-xxx/xxx"
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">🟢 Interstitial Android</label>
                  <input type="text" value={settings.interstitialAdUnitAndroid ?? ''}
                    onChange={e => setSettings(s => ({ ...s, interstitialAdUnitAndroid: e.target.value }))}
                    placeholder="ca-app-pub-xxx/xxx"
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">🍎 Interstitial iOS</label>
                  <input type="text" value={settings.interstitialAdUnitIos ?? ''}
                    onChange={e => setSettings(s => ({ ...s, interstitialAdUnitIos: e.target.value }))}
                    placeholder="ca-app-pub-xxx/xxx"
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">🟢 Rewarded Android</label>
                  <input type="text" value={settings.rewardedAdUnitAndroid ?? ''}
                    onChange={e => setSettings(s => ({ ...s, rewardedAdUnitAndroid: e.target.value }))}
                    placeholder="ca-app-pub-xxx/xxx"
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">🍎 Rewarded iOS</label>
                  <input type="text" value={settings.rewardedAdUnitIos ?? ''}
                    onChange={e => setSettings(s => ({ ...s, rewardedAdUnitIos: e.target.value }))}
                    placeholder="ca-app-pub-xxx/xxx"
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
                </div>
              </div>
              <div className="bg-blue-50 rounded-xl p-3 text-xs text-blue-700">
                <strong>App IDs (build-time, không thay đổi được):</strong><br/>
                🟢 Android: <span className="font-mono">ca-app-pub-9958247766651079~2543356751</span><br/>
                🍎 iOS: <span className="font-mono">ca-app-pub-9958247766651079~5873287169</span>
              </div>
            </div>
          )}
        </div>

        {/* RevenueCat IAP */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-1">In-App Purchase (RevenueCat)</h2>
          <p className="text-sm text-gray-400 mb-4">Webhook nhận sự kiện mua hàng từ RevenueCat để kích hoạt VIP tự động</p>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Webhook Secret (Authorization token)</label>
              <input type="text" value={settings.revenueCatWebhookSecret ?? ''}
                onChange={e => setSettings(s => ({ ...s, revenueCatWebhookSecret: e.target.value }))}
                placeholder="Dán secret từ RevenueCat dashboard vào đây"
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div className="bg-amber-50 rounded-xl p-3 text-xs text-amber-800 space-y-1">
              <p><strong>Webhook URL:</strong> <span className="font-mono">https://lephap.io.vn/api/webhook/revenuecat</span></p>
              <p>Cấu hình URL này trong <strong>RevenueCat Dashboard → Project → Integrations → Webhooks</strong></p>
              <p>Sau đó copy Authorization Secret từ RC và dán vào ô trên rồi nhấn Lưu.</p>
            </div>
          </div>
        </div>

        {/* Allowed Countries */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <div className="flex items-start justify-between mb-1">
            <div>
              <h2 className="text-base font-bold text-gray-900">Quốc gia được phép (Whitelist)</h2>
              <p className="text-sm text-gray-400 mt-0.5">
                {settings.allowedCountries.length === 0
                  ? 'Để trống = cho phép tất cả quốc gia'
                  : `Chỉ hiển thị server của ${settings.allowedCountries.length} quốc gia đã chọn`}
              </p>
            </div>
          </div>
          {settings.allowedCountries.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3 mb-3">
              {settings.allowedCountries.map(code => {
                const c = ALL_COUNTRIES.find(x => x.code === code);
                return (
                  <span key={code} className="inline-flex items-center gap-1.5 bg-indigo-50 text-indigo-700 px-3 py-1 rounded-full text-sm font-medium">
                    {flag(code)} {c?.name ?? code}
                    <button onClick={() => toggleCountry(code, 'allowed')} className="text-indigo-400 hover:text-indigo-700 ml-0.5">×</button>
                  </span>
                );
              })}
            </div>
          )}
          <select value="" onChange={e => { if (e.target.value) toggleCountry(e.target.value, 'allowed'); }}
            className="mt-2 px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white">
            <option value="">+ Thêm quốc gia vào whitelist...</option>
            {availableForAllowed.map(c => <option key={c.code} value={c.code}>{flag(c.code)} {c.name}</option>)}
          </select>
        </div>

        {/* Blocked Countries */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <div className="mb-1">
            <h2 className="text-base font-bold text-gray-900">Quốc gia bị chặn (Blacklist)</h2>
            <p className="text-sm text-gray-400 mt-0.5">Server từ các quốc gia này sẽ bị ẩn khỏi danh sách Free</p>
          </div>
          {settings.blockedCountries.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-3 mb-3">
              {settings.blockedCountries.map(code => {
                const c = ALL_COUNTRIES.find(x => x.code === code);
                return (
                  <span key={code} className="inline-flex items-center gap-1.5 bg-red-50 text-red-700 px-3 py-1 rounded-full text-sm font-medium">
                    {flag(code)} {c?.name ?? code}
                    <button onClick={() => toggleCountry(code, 'blocked')} className="text-red-400 hover:text-red-700 ml-0.5">×</button>
                  </span>
                );
              })}
            </div>
          )}
          <select value="" onChange={e => { if (e.target.value) toggleCountry(e.target.value, 'blocked'); }}
            className="mt-2 px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white">
            <option value="">+ Chặn quốc gia...</option>
            {availableForBlocked.map(c => <option key={c.code} value={c.code}>{flag(c.code)} {c.name}</option>)}
          </select>
        </div>
      </div>
    </div>
  );
}
