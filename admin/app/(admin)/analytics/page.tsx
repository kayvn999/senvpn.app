'use client';

import { useEffect, useState } from 'react';

interface ApiUser { uid: string; email: string; tier: string; createdAt: string | null; }
interface ApiConn { id: string; serverCountry: string; connectedAt: string | null; }

function BarChart({ data, max, color }: { data: { label: string; value: number }[]; max: number; color: string }) {
  return (
    <div className="flex items-end gap-1.5 h-32">
      {data.map((d, i) => (
        <div key={i} className="flex-1 flex flex-col items-center gap-1">
          <span className="text-xs text-gray-400">{d.value > 0 ? d.value : ''}</span>
          <div className="w-full rounded-t-md transition-all duration-500" style={{
            height: max > 0 ? `${(d.value / max) * 100}%` : '4px',
            minHeight: '4px',
            backgroundColor: color,
            opacity: d.value === 0 ? 0.2 : 1,
          }} />
          <span className="text-xs text-gray-400">{d.label}</span>
        </div>
      ))}
    </div>
  );
}

export default function AnalyticsPage() {
  const [users, setUsers] = useState<ApiUser[]>([]);
  const [logs, setLogs] = useState<ApiConn[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetch('/api/admin/users').then(r => r.json()),
      fetch('/api/admin/connections').then(r => r.json()),
    ]).then(([u, l]) => { setUsers(Array.isArray(u) ? u : []); setLogs(Array.isArray(l) ? l : []); })
      .finally(() => setLoading(false));
  }, []);

  const last7 = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (6 - i)); return d;
  });

  const regByDay = last7.map((d) => ({
    label: `${d.getDate()}/${d.getMonth() + 1}`,
    value: users.filter((u) => {
      if (!u.createdAt) return false;
      return new Date(u.createdAt).toDateString() === d.toDateString();
    }).length,
  }));

  const connByDay = last7.map((d) => ({
    label: `${d.getDate()}/${d.getMonth() + 1}`,
    value: logs.filter((l) => {
      if (!l.connectedAt) return false;
      return new Date(l.connectedAt).toDateString() === d.toDateString();
    }).length,
  }));

  const vip = users.filter((u) => u.tier === 'vip').length;
  const free = users.length - vip;
  const vipPct = users.length > 0 ? Math.round((vip / users.length) * 100) : 0;
  const maxReg = Math.max(...regByDay.map((d) => d.value), 1);
  const maxConn = Math.max(...connByDay.map((d) => d.value), 1);

  const countryMap: Record<string, number> = {};
  logs.forEach((l) => { if (l.serverCountry) countryMap[l.serverCountry] = (countryMap[l.serverCountry] ?? 0) + 1; });
  const topCountries = Object.entries(countryMap).sort((a, b) => b[1] - a[1]).slice(0, 5);

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Thống kê</h1>
        <p className="text-sm text-gray-500 mt-1">Biểu đồ người dùng và hoạt động hệ thống</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {[
          { label: 'Tổng người dùng', value: users.length, color: 'text-indigo-600', bg: 'bg-indigo-50' },
          { label: 'VIP', value: vip, color: 'text-yellow-600', bg: 'bg-yellow-50' },
          { label: 'Free', value: free, color: 'text-blue-600', bg: 'bg-blue-50' },
          { label: 'Tỷ lệ VIP', value: `${vipPct}%`, color: 'text-green-600', bg: 'bg-green-50' },
        ].map((s) => (
          <div key={s.label} className={`${s.bg} rounded-2xl p-5`}>
            <p className={`text-2xl font-bold ${s.color}`}>{loading ? '...' : s.value}</p>
            <p className="text-xs text-gray-500 mt-1">{s.label}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 mb-5">
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-sm font-bold text-gray-900 mb-4">Đăng ký mới (7 ngày qua)</h2>
          {loading ? <div className="h-32 bg-gray-50 rounded-xl animate-pulse" /> : <BarChart data={regByDay} max={maxReg} color="#6366f1" />}
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-sm font-bold text-gray-900 mb-4">Lượt kết nối (7 ngày qua)</h2>
          {loading ? (
            <div className="h-32 bg-gray-50 rounded-xl animate-pulse" />
          ) : logs.length === 0 ? (
            <div className="h-32 flex flex-col items-center justify-center text-gray-400">
              <p className="text-sm">Chưa có dữ liệu kết nối</p>
              <p className="text-xs mt-1">App cần ghi log vào collection <code>connections</code></p>
            </div>
          ) : (
            <BarChart data={connByDay} max={maxConn} color="#10b981" />
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-sm font-bold text-gray-900 mb-4">Phân bố tài khoản</h2>
          <div className="flex items-center gap-4 mb-4">
            <div className="flex-1 bg-gray-100 rounded-full h-4 overflow-hidden">
              <div className="h-full bg-yellow-400 rounded-full transition-all" style={{ width: `${vipPct}%` }} />
            </div>
            <span className="text-sm font-bold text-yellow-600 w-12">{vipPct}% VIP</span>
          </div>
          <div className="flex gap-6 text-sm">
            <div className="flex items-center gap-2"><div className="w-3 h-3 rounded-full bg-yellow-400" /><span className="text-gray-600">VIP: {vip}</span></div>
            <div className="flex items-center gap-2"><div className="w-3 h-3 rounded-full bg-gray-200" /><span className="text-gray-600">Free: {free}</span></div>
          </div>
        </div>
        <div className="bg-white rounded-2xl border border-gray-100 p-6">
          <h2 className="text-sm font-bold text-gray-900 mb-4">Server được dùng nhiều nhất</h2>
          {topCountries.length === 0 ? (
            <p className="text-sm text-gray-400">Chưa có dữ liệu</p>
          ) : (
            <div className="space-y-3">
              {topCountries.map(([country, count]) => (
                <div key={country} className="flex items-center gap-3">
                  <span className="text-sm text-gray-700 w-28 truncate">{country}</span>
                  <div className="flex-1 bg-gray-100 rounded-full h-2">
                    <div className="h-full bg-indigo-400 rounded-full" style={{ width: `${(count / topCountries[0][1]) * 100}%` }} />
                  </div>
                  <span className="text-xs text-gray-500 w-8 text-right">{count}</span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
