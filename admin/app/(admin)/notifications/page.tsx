'use client';

import { useEffect, useState } from 'react';

interface NotificationLog { id: string; title: string; body: string; target: string; sentAt: string | null; }

function formatDate(iso: string | null) {
  if (!iso) return '';
  return new Date(iso).toLocaleString('vi-VN');
}

export default function NotificationsPage() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [target, setTarget] = useState<'all' | 'vip' | 'free'>('all');
  const [sending, setSending] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');
  const [logs, setLogs] = useState<NotificationLog[]>([]);
  const [loadingLogs, setLoadingLogs] = useState(true);

  const loadLogs = async () => {
    setLoadingLogs(true);
    try {
      const res = await fetch('/api/admin/notifications');
      if (res.ok) setLogs(await res.json());
    } finally {
      setLoadingLogs(false);
    }
  };

  useEffect(() => { loadLogs(); }, []);

  const handleSend = async () => {
    if (!title.trim() || !body.trim()) { setError('Vui lòng điền tiêu đề và nội dung.'); return; }
    setSending(true); setError('');
    try {
      const res = await fetch('/api/send-notification', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, body, target }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error || 'Gửi thất bại');

      await fetch('/api/admin/notifications', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, body, target }),
      });
      await loadLogs();
      setTitle(''); setBody(''); setSent(true);
      setTimeout(() => setSent(false), 3000);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Gửi thông báo thất bại.');
    } finally {
      setSending(false);
    }
  };

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Gửi thông báo</h1>
        <p className="text-sm text-gray-500 mt-1">Push notification đến người dùng qua Firebase Cloud Messaging</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-5">Soạn thông báo</h2>

          {error && <div className="mb-4 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">{error}</div>}
          {sent && <div className="mb-4 bg-green-50 border border-green-200 rounded-xl px-4 py-3 text-sm text-green-700">✅ Đã gửi thông báo thành công!</div>}

          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Đối tượng nhận</label>
              <div className="flex gap-2">
                {(['all', 'vip', 'free'] as const).map((t) => (
                  <button key={t} onClick={() => setTarget(t)}
                    className={`flex-1 py-2 rounded-xl text-sm font-semibold transition-colors ${target === t ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
                    {t === 'all' ? '👥 Tất cả' : t === 'vip' ? '⭐ VIP' : '🆓 Free'}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Tiêu đề</label>
              <input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="Thông báo từ SEN VPN"
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300" />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Nội dung</label>
              <textarea rows={4} value={body} onChange={(e) => setBody(e.target.value)} placeholder="Nội dung thông báo..."
                className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 resize-none" />
            </div>

            {(title || body) && (
              <div className="bg-gray-900 rounded-2xl p-4 text-white">
                <p className="text-xs text-gray-400 mb-2">Xem trước trên điện thoại</p>
                <div className="bg-white rounded-xl p-3 text-gray-900">
                  <div className="flex items-center gap-2 mb-1">
                    <div className="w-5 h-5 bg-indigo-500 rounded-md" />
                    <span className="text-xs font-bold">SEN VPN</span>
                  </div>
                  <p className="text-sm font-semibold">{title || '(tiêu đề)'}</p>
                  <p className="text-xs text-gray-600 mt-0.5">{body || '(nội dung)'}</p>
                </div>
              </div>
            )}

            <button onClick={handleSend} disabled={sending}
              className="w-full py-3 bg-indigo-600 text-white rounded-xl text-sm font-bold hover:bg-indigo-700 disabled:opacity-60 flex items-center justify-center gap-2">
              {sending ? (
                <><div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Đang gửi...</>
              ) : (
                <><svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}><path strokeLinecap="round" strokeLinejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" /></svg> Gửi thông báo</>
              )}
            </button>
            <p className="text-xs text-gray-400 text-center">Thông báo được gửi qua Firebase Cloud Messaging</p>
          </div>
        </div>

        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-base font-bold text-gray-900 mb-5">Lịch sử gửi</h2>
          {loadingLogs ? (
            <div className="space-y-3">{[...Array(4)].map((_, i) => <div key={i} className="h-16 bg-gray-50 rounded-xl animate-pulse" />)}</div>
          ) : logs.length === 0 ? (
            <div className="text-center py-10 text-gray-400 text-sm">Chưa có thông báo nào được gửi</div>
          ) : (
            <div className="space-y-3 max-h-[480px] overflow-y-auto">
              {logs.map((log) => (
                <div key={log.id} className="bg-gray-50 rounded-xl p-4">
                  <div className="flex items-center justify-between mb-1">
                    <p className="text-sm font-semibold text-gray-900">{log.title}</p>
                    <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${
                      log.target === 'all' ? 'bg-indigo-100 text-indigo-600' :
                      log.target === 'vip' ? 'bg-yellow-100 text-yellow-700' : 'bg-blue-100 text-blue-600'
                    }`}>
                      {log.target === 'all' ? 'Tất cả' : log.target === 'vip' ? 'VIP' : 'Free'}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500">{log.body}</p>
                  <p className="text-xs text-gray-400 mt-1">{formatDate(log.sentAt)}</p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
