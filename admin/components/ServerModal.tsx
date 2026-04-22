'use client';

import { useState, useEffect } from 'react';
import type { VpnServer } from '@/app/(admin)/servers/page';

interface ServerModalProps {
  server?: VpnServer | null;
  onClose: () => void;
  onSaved: () => void;
}

const PROTOCOLS = ['OpenVPN', 'WireGuard', 'IKEv2', 'L2TP', 'SSTP', 'VLESS', 'VMess', 'Shadowsocks'];

const COUNTRIES: { name: string; code: string }[] = [
  { name: 'Việt Nam', code: 'VN' },
  { name: 'Hoa Kỳ', code: 'US' },
  { name: 'Nhật Bản', code: 'JP' },
  { name: 'Hàn Quốc', code: 'KR' },
  { name: 'Singapore', code: 'SG' },
  { name: 'Đức', code: 'DE' },
  { name: 'Pháp', code: 'FR' },
  { name: 'Anh', code: 'GB' },
  { name: 'Canada', code: 'CA' },
  { name: 'Úc', code: 'AU' },
  { name: 'Hà Lan', code: 'NL' },
  { name: 'Thụy Điển', code: 'SE' },
  { name: 'Thái Lan', code: 'TH' },
  { name: 'Ấn Độ', code: 'IN' },
  { name: 'Brazil', code: 'BR' },
  { name: 'Thổ Nhĩ Kỳ', code: 'TR' },
  { name: 'Nga', code: 'RU' },
  { name: 'Trung Quốc', code: 'CN' },
  { name: 'Hong Kong', code: 'HK' },
  { name: 'Đài Loan', code: 'TW' },
  { name: 'Malaysia', code: 'MY' },
  { name: 'Indonesia', code: 'ID' },
  { name: 'Philippines', code: 'PH' },
];

interface FormState {
  name: string; host: string; port: number;
  country: string; countryCode: string; protocol: string;
  isActive: boolean; isPremium: boolean; load: number;
  ping: number; speedMbps: number; ovpnConfig: string;
}

const emptyForm: FormState = {
  name: '', host: '', port: 1194, country: '', countryCode: '',
  protocol: 'OpenVPN', isActive: true, isPremium: false,
  load: 0, ping: 99, speedMbps: 100, ovpnConfig: '',
};

export default function ServerModal({ server, onClose, onSaved }: ServerModalProps) {
  const [form, setForm] = useState<FormState>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (server) {
      setForm({
        name: server.name,
        host: server.host,
        port: server.port,
        country: server.country,
        countryCode: server.countryCode,
        protocol: server.protocol,
        isActive: server.isActive,
        isPremium: server.isPremium,
        load: server.load ?? 0,
        ping: server.ping ?? 99,
        speedMbps: server.speedMbps ?? 100,
        ovpnConfig: server.ovpnConfig ?? '',
      });
    } else {
      setForm(emptyForm);
    }
  }, [server]);

  const handleCountryChange = (code: string) => {
    const found = COUNTRIES.find(c => c.code === code);
    setForm(f => ({ ...f, countryCode: code, country: found?.name ?? code }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    if (!form.name.trim()) return setError('Tên máy chủ không được để trống.');
    if (!form.host.trim()) return setError('Host / IP không được để trống.');
    if (!form.countryCode) return setError('Vui lòng chọn quốc gia.');
    if (form.port < 1 || form.port > 65535) return setError('Cổng phải từ 1 đến 65535.');

    setSaving(true);
    try {
      const url = server ? `/api/admin/servers/${server.id}` : '/api/admin/servers';
      const method = server ? 'PUT' : 'POST';
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...form, isFree: !form.isPremium }),
      });
      if (!res.ok) throw new Error(await res.text());
      onSaved();
      onClose();
    } catch (err) {
      console.error(err);
      setError('Lỗi khi lưu dữ liệu. Vui lòng thử lại.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white rounded-2xl shadow-xl w-full max-w-lg max-h-[90vh] flex flex-col">
        <div className="flex items-center justify-between px-6 py-5 border-b border-gray-100">
          <h2 className="text-lg font-semibold text-gray-900">
            {server ? 'Chỉnh sửa máy chủ' : 'Thêm máy chủ mới'}
          </h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 p-1 rounded-lg hover:bg-gray-100 transition-colors">
            <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto px-6 py-5 space-y-4">
          {error && (
            <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">{error}</div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Tên máy chủ <span className="text-red-500">*</span></label>
            <input type="text" value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
              placeholder="vd: VN Server #1"
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent" />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Host / IP <span className="text-red-500">*</span></label>
            <input type="text" value={form.host} onChange={e => setForm(f => ({ ...f, host: e.target.value }))}
              placeholder="vd: 192.168.1.1 hoặc vpn.example.com"
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent" />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Cổng (Port) <span className="text-red-500">*</span></label>
              <input type="number" value={form.port} onChange={e => setForm(f => ({ ...f, port: Number(e.target.value) }))}
                min={1} max={65535}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Giao thức</label>
              <select value={form.protocol} onChange={e => setForm(f => ({ ...f, protocol: e.target.value }))}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent bg-white">
                {PROTOCOLS.map(p => <option key={p} value={p}>{p}</option>)}
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Quốc gia <span className="text-red-500">*</span></label>
            <select value={form.countryCode} onChange={e => handleCountryChange(e.target.value)}
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent bg-white">
              <option value="">-- Chọn quốc gia --</option>
              {COUNTRIES.map(c => <option key={c.code} value={c.code}>{c.name} ({c.code})</option>)}
            </select>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tải (%)</label>
              <input type="number" value={form.load} onChange={e => setForm(f => ({ ...f, load: Number(e.target.value) }))}
                min={0} max={100}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Ping (ms)</label>
              <input type="number" value={form.ping} onChange={e => setForm(f => ({ ...f, ping: Number(e.target.value) }))}
                min={0}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Speed (Mbps)</label>
              <input type="number" value={form.speedMbps} onChange={e => setForm(f => ({ ...f, speedMbps: Number(e.target.value) }))}
                min={0}
                className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent" />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">OpenVPN Config <span className="text-gray-400 font-normal">— tùy chọn</span></label>
            <textarea value={form.ovpnConfig} onChange={e => setForm(f => ({ ...f, ovpnConfig: e.target.value }))}
              rows={4} placeholder="Paste nội dung file .ovpn..."
              className="w-full px-3 py-2 border border-gray-200 rounded-xl text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent resize-none" />
          </div>

          <div className="space-y-3 pt-1">
            <label className="flex items-center justify-between p-3 bg-gray-50 rounded-xl cursor-pointer">
              <div>
                <p className="text-sm font-medium text-gray-800">Kích hoạt máy chủ</p>
                <p className="text-xs text-gray-400">Máy chủ sẽ hiển thị cho người dùng</p>
              </div>
              <button type="button" onClick={() => setForm(f => ({ ...f, isActive: !f.isActive }))}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${form.isActive ? 'bg-indigo-500' : 'bg-gray-300'}`}>
                <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-sm transition-transform ${form.isActive ? 'translate-x-6' : 'translate-x-1'}`} />
              </button>
            </label>
            <label className="flex items-center justify-between p-3 bg-gray-50 rounded-xl cursor-pointer">
              <div>
                <p className="text-sm font-medium text-gray-800">Máy chủ VIP</p>
                <p className="text-xs text-gray-400">Chỉ người dùng VIP mới kết nối được</p>
              </div>
              <button type="button" onClick={() => setForm(f => ({ ...f, isPremium: !f.isPremium }))}
                className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${form.isPremium ? 'bg-yellow-400' : 'bg-gray-300'}`}>
                <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow-sm transition-transform ${form.isPremium ? 'translate-x-6' : 'translate-x-1'}`} />
              </button>
            </label>
          </div>
        </form>

        <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100">
          <button type="button" onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 hover:bg-gray-100 rounded-xl transition-colors">
            Hủy
          </button>
          <button type="submit" disabled={saving} onClick={handleSubmit}
            className="flex items-center gap-2 px-5 py-2 bg-indigo-500 hover:bg-indigo-600 disabled:bg-indigo-300 text-white text-sm font-semibold rounded-xl transition-colors">
            {saving ? (
              <><div className="animate-spin h-4 w-4 border-b-2 border-white rounded-full" />Đang lưu...</>
            ) : (
              server ? 'Cập nhật' : 'Thêm máy chủ'
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
