'use client';

import { useEffect, useState } from 'react';

interface ConnectionLog {
  id: string;
  uid: string;
  email: string;
  serverName: string;
  serverCountry: string;
  connectedAt: string | null;
  disconnectedAt: string | null;
  dataMB: number | null;
}

function fmt(iso?: string | null) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('vi-VN');
}

function duration(start?: string | null, end?: string | null) {
  if (!start || !end) return '—';
  const ms = new Date(end).getTime() - new Date(start).getTime();
  if (ms <= 0) return '—';
  const m = Math.floor(ms / 60000);
  const h = Math.floor(m / 60);
  if (h > 0) return `${h}g ${m % 60}p`;
  return `${m} phút`;
}

export default function HistoryPage() {
  const [logs, setLogs] = useState<ConnectionLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetch('/api/admin/connections')
      .then((r) => r.json())
      .then((data) => {
        setLogs(Array.isArray(data) ? data : []);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const filtered = logs.filter((l) =>
    !search ||
    l.email?.toLowerCase().includes(search.toLowerCase()) ||
    l.serverName?.toLowerCase().includes(search.toLowerCase()) ||
    l.serverCountry?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Lịch sử kết nối</h1>
        <p className="text-sm text-gray-500 mt-1">Xem ai đã kết nối server nào và thời gian bao lâu</p>
      </div>

      <div className="mb-4">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Tìm theo email, tên server, quốc gia..."
          className="w-full max-w-sm px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
        />
      </div>

      {loading ? (
        <div className="space-y-3">
          {[...Array(8)].map((_, i) => <div key={i} className="h-14 bg-white rounded-2xl border border-gray-100 animate-pulse" />)}
        </div>
      ) : filtered.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 p-12 text-center">
          <div className="w-14 h-14 bg-indigo-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-7 h-7 text-indigo-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="text-gray-500 font-medium">Chưa có dữ liệu lịch sử</p>
          <p className="text-sm text-gray-400 mt-2 max-w-sm mx-auto">
            App Flutter cần ghi log kết nối vào Firestore collection <code className="bg-gray-100 px-1 rounded">connections</code> với các field: uid, email, serverName, serverCountry, connectedAt, disconnectedAt, dataMB
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
          <div className="px-5 py-3 border-b border-gray-100 flex items-center justify-between">
            <p className="text-sm text-gray-500">{filtered.length} kết nối</p>
          </div>
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Người dùng</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Server</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden lg:table-cell">Thời gian kết nối</th>
                <th className="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden lg:table-cell">Thời lượng</th>
                <th className="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Data</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-5 py-3.5">
                    <p className="font-medium text-gray-900 text-sm">{log.email ?? log.uid}</p>
                  </td>
                  <td className="px-5 py-3.5 hidden md:table-cell">
                    <p className="text-sm text-gray-700">{log.serverName}</p>
                    <p className="text-xs text-gray-400">{log.serverCountry}</p>
                  </td>
                  <td className="px-5 py-3.5 hidden lg:table-cell">
                    <p className="text-xs text-gray-600">{fmt(log.connectedAt)}</p>
                    {log.disconnectedAt && (
                      <p className="text-xs text-gray-400">→ {fmt(log.disconnectedAt)}</p>
                    )}
                  </td>
                  <td className="px-5 py-3.5 text-center hidden lg:table-cell">
                    <span className="text-xs text-gray-600">{duration(log.connectedAt, log.disconnectedAt)}</span>
                  </td>
                  <td className="px-5 py-3.5 text-center">
                    <span className="text-xs font-medium text-indigo-600">
                      {log.dataMB != null ? `${log.dataMB} MB` : '—'}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
