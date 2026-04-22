'use client';

import { useEffect, useState } from 'react';
import { getAppVersion, saveAppVersion, AppVersion } from '@/lib/firestore';

export default function AppVersionPage() {
  const [form, setForm] = useState<AppVersion>({
    version: '1.0.0',
    buildNumber: 1,
    forceUpdate: false,
    minVersion: '1.0.0',
    releaseNotes: '',
    downloadUrl: '',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    getAppVersion().then((data) => {
      setForm(data);
      setLoading(false);
    });
  }, []);

  const handleSave = async () => {
    setSaving(true);
    setError('');
    try {
      await saveAppVersion(form);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch {
      setError('Lưu thất bại.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="animate-pulse space-y-4">{[...Array(4)].map((_, i) => <div key={i} className="h-16 bg-white rounded-2xl border border-gray-100" />)}</div>;
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Phiên bản App</h1>
          <p className="text-sm text-gray-500 mt-1">Quản lý version, force update và release notes</p>
        </div>
        <button
          onClick={handleSave}
          disabled={saving}
          className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 text-white rounded-xl text-sm font-semibold hover:bg-indigo-700 disabled:opacity-60"
        >
          {saving ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> :
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>}
          {saving ? 'Đang lưu...' : 'Lưu'}
        </button>
      </div>

      {error && <div className="mb-4 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">{error}</div>}
      {saved && (
        <div className="mb-4 bg-green-50 border border-green-200 rounded-xl px-4 py-3 text-sm text-green-700 flex items-center gap-2">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Đã lưu! App sẽ tự động nhận thông tin version mới.
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {/* Version info */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-4">
          <h2 className="text-base font-bold text-gray-900">Thông tin phiên bản</h2>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Version hiện tại</label>
              <input
                value={form.version}
                onChange={(e) => setForm((f) => ({ ...f, version: e.target.value }))}
                placeholder="1.0.0"
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Build Number</label>
              <input
                type="number"
                value={form.buildNumber}
                onChange={(e) => setForm((f) => ({ ...f, buildNumber: Number(e.target.value) }))}
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Version tối thiểu (min version)</label>
            <input
              value={form.minVersion}
              onChange={(e) => setForm((f) => ({ ...f, minVersion: e.target.value }))}
              placeholder="1.0.0"
              className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
            />
            <p className="text-xs text-gray-400 mt-1">App cũ hơn min version sẽ bị yêu cầu cập nhật</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Link tải (Download URL)</label>
            <input
              value={form.downloadUrl}
              onChange={(e) => setForm((f) => ({ ...f, downloadUrl: e.target.value }))}
              placeholder="https://play.google.com/store/apps/..."
              className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
            />
          </div>
        </div>

        {/* Force update + release notes */}
        <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-4">
          <h2 className="text-base font-bold text-gray-900">Cập nhật bắt buộc</h2>

          <label className="flex items-center justify-between p-4 bg-gray-50 rounded-xl cursor-pointer">
            <div>
              <p className="font-medium text-gray-800">Bắt buộc cập nhật (Force Update)</p>
              <p className="text-sm text-gray-400 mt-0.5">App sẽ hiển thị dialog bắt buộc cập nhật khi mở</p>
            </div>
            <button
              type="button"
              onClick={() => setForm((f) => ({ ...f, forceUpdate: !f.forceUpdate }))}
              className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                form.forceUpdate ? 'bg-red-500' : 'bg-gray-300'
              }`}
            >
              <span className={`inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform ${
                form.forceUpdate ? 'translate-x-6' : 'translate-x-1'
              }`} />
            </button>
          </label>

          {form.forceUpdate && (
            <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">
              ⚠️ Force Update đang BẬT — tất cả người dùng có version cũ hơn <strong>{form.minVersion}</strong> sẽ bị yêu cầu cập nhật.
            </div>
          )}

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Release Notes</label>
            <textarea
              rows={6}
              value={form.releaseNotes}
              onChange={(e) => setForm((f) => ({ ...f, releaseNotes: e.target.value }))}
              placeholder="• Thêm tính năng mới&#10;• Sửa lỗi kết nối&#10;• Cải thiện hiệu suất"
              className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 resize-none"
            />
            <p className="text-xs text-gray-400 mt-1">Hiển thị trong dialog cập nhật trên app</p>
          </div>
        </div>
      </div>

      {/* Version timeline */}
      <div className="mt-5 bg-white rounded-2xl border border-gray-100 p-6">
        <h2 className="text-base font-bold text-gray-900 mb-4">Cấu hình hiện tại</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          {[
            { label: 'Version', value: form.version },
            { label: 'Build', value: `#${form.buildNumber}` },
            { label: 'Min Version', value: form.minVersion },
            { label: 'Force Update', value: form.forceUpdate ? '🔴 BẬT' : '🟢 TẮT' },
          ].map((s) => (
            <div key={s.label} className="bg-gray-50 rounded-xl p-4 text-center">
              <p className="text-lg font-bold text-gray-900">{s.value}</p>
              <p className="text-xs text-gray-500 mt-1">{s.label}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
