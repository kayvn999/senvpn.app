'use client';

import { useEffect, useState } from 'react';

interface ActivationKey {
  key: string;
  durationDays: number;
  note: string;
  createdAt: string;
  isUsed: boolean;
  usedAt?: string;
  usedByDeviceId?: string;
}

export default function KeysPage() {
  const [keys, setKeys] = useState<ActivationKey[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [form, setForm] = useState({ durationDays: 30, note: '', count: 1 });
  const [copied, setCopied] = useState('');
  const [filter, setFilter] = useState<'all' | 'unused' | 'used'>('all');
  const [actionKey, setActionKey] = useState('');

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/keys');
      setKeys(await res.json());
    } finally { setLoading(false); }
  };

  useEffect(() => { load(); }, []);

  const generate = async () => {
    setGenerating(true);
    try {
      const res = await fetch('/api/admin/keys', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      await res.json();
      await load();
    } finally { setGenerating(false); }
  };

  const deleteKey = async (key: string) => {
    if (!confirm(`Xóa vĩnh viễn key ${key}?`)) return;
    setActionKey(key);
    try {
      await fetch(`/api/admin/keys/${encodeURIComponent(key)}`, { method: 'DELETE' });
      setKeys(ks => ks.filter(k => k.key !== key));
    } finally { setActionKey(''); }
  };

  const revokeKey = async (key: string) => {
    if (!confirm(`Hủy kích hoạt key ${key}?\nVIP của người dùng sẽ bị thu hồi và key sẽ dùng được lại.`)) return;
    setActionKey(key);
    try {
      await fetch(`/api/admin/keys/${encodeURIComponent(key)}`, { method: 'POST' });
      await load();
    } finally { setActionKey(''); }
  };

  const copyKey = (key: string) => {
    navigator.clipboard.writeText(key);
    setCopied(key);
    setTimeout(() => setCopied(''), 2000);
  };

  const copyAll = () => {
    const unused = keys.filter(k => !k.isUsed).map(k => k.key).join('\n');
    navigator.clipboard.writeText(unused);
    setCopied('all');
    setTimeout(() => setCopied(''), 2000);
  };

  const filtered = keys.filter(k =>
    filter === 'all' ? true : filter === 'unused' ? !k.isUsed : k.isUsed
  );

  const unusedCount = keys.filter(k => !k.isUsed).length;
  const usedCount = keys.filter(k => k.isUsed).length;

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Mã kích hoạt VIP</h1>
          <p className="text-sm text-gray-500 mt-1">Tạo và quản lý key để bán VIP bên ngoài CH Play / App Store</p>
        </div>
        <div className="flex gap-2">
          {unusedCount > 0 && (
            <button onClick={copyAll}
              className="flex items-center gap-2 px-4 py-2.5 border border-gray-200 text-gray-700 rounded-xl text-sm font-medium hover:bg-gray-50 transition-colors">
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              {copied === 'all' ? 'Đã copy!' : `Copy ${unusedCount} key chưa dùng`}
            </button>
          )}
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: 'Tổng key', value: keys.length, color: 'indigo' },
          { label: 'Chưa dùng', value: unusedCount, color: 'green' },
          { label: 'Đã dùng', value: usedCount, color: 'gray' },
        ].map(s => (
          <div key={s.label} className="bg-white rounded-2xl border border-gray-100 p-5">
            <p className="text-sm text-gray-500">{s.label}</p>
            <p className={`text-3xl font-bold mt-1 ${s.color === 'green' ? 'text-green-600' : s.color === 'indigo' ? 'text-indigo-600' : 'text-gray-400'}`}>{s.value}</p>
          </div>
        ))}
      </div>

      {/* Generate form */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6 mb-6">
        <h2 className="text-base font-bold text-gray-900 mb-4">Tạo mã mới</h2>
        <div className="flex flex-wrap gap-4 items-end">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Số ngày VIP</label>
            <select value={form.durationDays} onChange={e => setForm(f => ({ ...f, durationDays: Number(e.target.value) }))}
              className="px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 bg-white">
              <option value={7}>7 ngày (1 tuần)</option>
              <option value={30}>30 ngày (1 tháng)</option>
              <option value={90}>90 ngày (3 tháng)</option>
              <option value={180}>180 ngày (6 tháng)</option>
              <option value={365}>365 ngày (1 năm)</option>
              <option value={9999}>Vĩnh viễn</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Số lượng</label>
            <input type="number" min={1} max={100} value={form.count}
              onChange={e => setForm(f => ({ ...f, count: Number(e.target.value) }))}
              className="w-24 px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
          </div>
          <div className="flex-1 min-w-48">
            <label className="block text-sm font-medium text-gray-700 mb-1">Ghi chú (tùy chọn)</label>
            <input type="text" value={form.note} placeholder="VD: Batch tháng 4, Đại lý Hà Nội..."
              onChange={e => setForm(f => ({ ...f, note: e.target.value }))}
              className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
          </div>
          <button onClick={generate} disabled={generating}
            className="flex items-center gap-2 px-5 py-2.5 bg-indigo-600 text-white rounded-xl text-sm font-semibold hover:bg-indigo-700 disabled:opacity-60 transition-colors">
            {generating ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> : (
              <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
              </svg>
            )}
            {generating ? 'Đang tạo...' : `Tạo ${form.count} key`}
          </button>
        </div>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1 mb-4 bg-gray-100 p-1 rounded-xl w-fit">
        {(['all', 'unused', 'used'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)}
            className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-colors ${filter === f ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'}`}>
            {f === 'all' ? 'Tất cả' : f === 'unused' ? 'Chưa dùng' : 'Đã dùng'}
          </button>
        ))}
      </div>

      {/* Key list */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-400 text-sm">Đang tải...</div>
        ) : filtered.length === 0 ? (
          <div className="p-8 text-center text-gray-400 text-sm">
            {keys.length === 0 ? 'Chưa có key nào. Tạo key đầu tiên ở trên.' : 'Không có key nào phù hợp.'}
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100 bg-gray-50">
                <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Mã key</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Thời hạn</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Ghi chú</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Trạng thái</th>
                <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Ngày tạo</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map(k => (
                <tr key={k.key} className={`hover:bg-gray-50/50 ${k.isUsed ? 'opacity-60' : ''}`}>
                  <td className="px-5 py-3.5">
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-semibold text-gray-900 tracking-wider">{k.key}</span>
                      <button onClick={() => copyKey(k.key)}
                        className="text-gray-300 hover:text-indigo-500 transition-colors">
                        {copied === k.key ? (
                          <svg className="w-4 h-4 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                          </svg>
                        ) : (
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                          </svg>
                        )}
                      </button>
                    </div>
                  </td>
                  <td className="px-4 py-3.5">
                    <span className="font-medium text-gray-700">
                      {k.durationDays === 9999 ? 'Vĩnh viễn' : `${k.durationDays} ngày`}
                    </span>
                  </td>
                  <td className="px-4 py-3.5 text-gray-500 max-w-xs truncate">{k.note || '—'}</td>
                  <td className="px-4 py-3.5">
                    {k.isUsed ? (
                      <div>
                        <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-100 text-gray-500">
                          <span className="w-1.5 h-1.5 rounded-full bg-gray-400" />
                          Đã dùng
                        </span>
                        {k.usedByDeviceId && (
                          <p className="text-xs text-gray-400 mt-0.5 font-mono truncate max-w-32" title={k.usedByDeviceId}>
                            {k.usedByDeviceId.slice(0, 8)}...
                          </p>
                        )}
                      </div>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-green-50 text-green-700">
                        <span className="w-1.5 h-1.5 rounded-full bg-green-500" />
                        Khả dụng
                      </span>
                    )}
                  </td>
                  <td className="px-4 py-3.5 text-gray-400 text-xs">
                    {new Date(k.createdAt).toLocaleDateString('vi-VN')}
                    {k.usedAt && <p className="text-gray-300">Dùng: {new Date(k.usedAt).toLocaleDateString('vi-VN')}</p>}
                  </td>
                  <td className="px-4 py-3.5 text-right">
                    <div className="flex items-center justify-end gap-1.5">
                      {actionKey === k.key ? (
                        <div className="w-4 h-4 border-2 border-indigo-400 border-t-transparent rounded-full animate-spin" />
                      ) : (
                        <>
                          {k.isUsed && (
                            <button onClick={() => revokeKey(k.key)}
                              title="Hủy kích hoạt — Thu hồi VIP và reset key về chưa dùng"
                              className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-amber-50 text-amber-600 hover:bg-amber-100 transition-colors">
                              <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                                <path strokeLinecap="round" strokeLinejoin="round" d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636" />
                              </svg>
                              Hủy
                            </button>
                          )}
                          <button onClick={() => deleteKey(k.key)}
                            title="Xóa vĩnh viễn key này"
                            className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-red-50 text-red-500 hover:bg-red-100 transition-colors">
                            <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                              <path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                            </svg>
                            Xóa
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
