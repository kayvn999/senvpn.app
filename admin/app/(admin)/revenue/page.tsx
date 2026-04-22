'use client';

import { useEffect, useState } from 'react';

interface ApiUser {
  uid: string;
  email: string;
  displayName: string;
  tier: string;
  subscriptionExpiry: string | null;
  subscriptionGrantedAt: string | null;
  subscriptionDurationDays?: number;
  subscriptionPriceVnd?: number;
}

function fmtDate(iso: string | null) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('vi-VN');
}

function fmtVnd(amount: number) {
  if (amount === 0) return '0 ₫';
  if (amount >= 1_000_000) return `${(amount / 1_000_000).toFixed(1)}M ₫`;
  if (amount >= 1_000) return `${(amount / 1_000).toFixed(0)}K ₫`;
  return `${amount} ₫`;
}

function daysLeft(iso: string | null): number {
  if (!iso) return 0;
  const ms = new Date(iso).getTime() - Date.now();
  return Math.max(0, Math.ceil(ms / 86400000));
}

function isThisMonth(iso: string | null): boolean {
  if (!iso) return false;
  const d = new Date(iso);
  const now = new Date();
  return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
}

export default function RevenuePage() {
  const [users, setUsers] = useState<ApiUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetch('/api/admin/users').then(r => r.json())
      .then((data) => { setUsers(Array.isArray(data) ? data : []); })
      .finally(() => setLoading(false));
  }, []);

  const vipUsers = users.filter((u) => u.tier === 'vip');
  const activeVip = vipUsers.filter((u) => daysLeft(u.subscriptionExpiry) > 0);
  const expiredVip = vipUsers.filter((u) => daysLeft(u.subscriptionExpiry) === 0);

  const revenueThisMonth = users.reduce((sum, u) => {
    if (!isThisMonth(u.subscriptionGrantedAt)) return sum;
    return sum + (u.subscriptionPriceVnd ?? 0);
  }, 0);

  const revenueAllTime = users.reduce((sum, u) => sum + (u.subscriptionPriceVnd ?? 0), 0);

  const months = Array.from({ length: 6 }, (_, i) => {
    const d = new Date(); d.setMonth(d.getMonth() - (5 - i));
    return { year: d.getFullYear(), month: d.getMonth(), label: `${d.getMonth() + 1}/${d.getFullYear()}` };
  });

  const monthlyRevenue = months.map((m) => ({
    label: m.label,
    value: users.reduce((sum, u) => {
      if (!u.subscriptionGrantedAt) return sum;
      const d = new Date(u.subscriptionGrantedAt);
      if (d.getFullYear() === m.year && d.getMonth() === m.month) return sum + (u.subscriptionPriceVnd ?? 0);
      return sum;
    }, 0),
  }));
  const maxMonthly = Math.max(...monthlyRevenue.map((m) => m.value), 1);

  const filtered = vipUsers.filter((u) =>
    !search ||
    u.email?.toLowerCase().includes(search.toLowerCase()) ||
    u.displayName?.toLowerCase().includes(search.toLowerCase())
  );

  const statCards = [
    { label: 'Doanh thu tháng này', value: fmtVnd(revenueThisMonth), color: 'text-green-700', bg: 'bg-green-50', icon: '💰' },
    { label: 'Tổng doanh thu', value: fmtVnd(revenueAllTime), color: 'text-indigo-700', bg: 'bg-indigo-50', icon: '📊' },
    { label: 'VIP đang hoạt động', value: activeVip.length, color: 'text-yellow-700', bg: 'bg-yellow-50', icon: '⭐' },
    { label: 'VIP hết hạn', value: expiredVip.length, color: 'text-red-600', bg: 'bg-red-50', icon: '⏰' },
  ];

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Doanh thu</h1>
        <p className="text-sm text-gray-500 mt-1">Theo dõi doanh thu và trạng thái subscription VIP</p>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        {statCards.map((s) => (
          <div key={s.label} className={`${s.bg} rounded-2xl p-5`}>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-lg">{s.icon}</span>
              <p className="text-xs text-gray-500">{s.label}</p>
            </div>
            <p className={`text-xl font-bold ${s.color}`}>{loading ? '...' : s.value}</p>
          </div>
        ))}
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 p-6 mb-5">
        <h2 className="text-sm font-bold text-gray-900 mb-5">Doanh thu 6 tháng qua</h2>
        {loading ? (
          <div className="h-32 bg-gray-50 rounded-xl animate-pulse" />
        ) : revenueAllTime === 0 ? (
          <div className="h-32 flex flex-col items-center justify-center text-gray-400">
            <p className="text-sm">Chưa có doanh thu được ghi nhận</p>
            <p className="text-xs mt-1 text-gray-300">Nhập giá (₫) khi cấp VIP để theo dõi doanh thu</p>
          </div>
        ) : (
          <div className="flex items-end gap-3 h-32">
            {monthlyRevenue.map((m, i) => (
              <div key={i} className="flex-1 flex flex-col items-center gap-1">
                <span className="text-xs text-gray-400">{m.value > 0 ? fmtVnd(m.value) : ''}</span>
                <div className="w-full rounded-t-lg bg-indigo-400 transition-all duration-500"
                  style={{ height: `${(m.value / maxMonthly) * 100}%`, minHeight: '4px', opacity: m.value === 0 ? 0.2 : 1 }} />
                <span className="text-xs text-gray-400">{m.label}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {!loading && users.length > 0 && (
        <div className="bg-white rounded-2xl border border-gray-100 p-6 mb-5">
          <h2 className="text-sm font-bold text-gray-900 mb-3">Tỷ lệ chuyển đổi VIP</h2>
          <div className="flex items-center gap-4">
            <div className="flex-1 bg-gray-100 rounded-full h-5 overflow-hidden">
              <div className="h-full bg-gradient-to-r from-yellow-400 to-yellow-500 rounded-full transition-all"
                style={{ width: `${Math.round((vipUsers.length / users.length) * 100)}%` }} />
            </div>
            <span className="text-sm font-bold text-yellow-600 w-16 text-right">
              {Math.round((vipUsers.length / users.length) * 100)}%
            </span>
          </div>
          <div className="flex gap-6 mt-3 text-xs text-gray-500">
            <span>⭐ VIP: {vipUsers.length} người</span>
            <span>🆓 Free: {users.length - vipUsers.length} người</span>
          </div>
        </div>
      )}

      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
          <p className="text-sm font-semibold text-gray-900">Danh sách VIP ({vipUsers.length})</p>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Tìm email..."
            className="px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300 w-64"
          />
        </div>
        {loading ? (
          <div className="p-5 space-y-3">{[...Array(5)].map((_, i) => <div key={i} className="h-14 bg-gray-50 rounded-xl animate-pulse" />)}</div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center">
            <p className="text-gray-500 font-medium">Chưa có người dùng VIP</p>
            <p className="text-sm text-gray-400 mt-1">Cấp VIP cho người dùng trong trang Người dùng</p>
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-100">
                <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Người dùng</th>
                <th className="text-left px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Ngày cấp</th>
                <th className="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Hết hạn</th>
                <th className="text-center px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Còn lại</th>
                <th className="text-right px-5 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Thanh toán</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {filtered.map((u) => {
                const days = daysLeft(u.subscriptionExpiry);
                const isActive = days > 0;
                return (
                  <tr key={u.uid} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-3.5">
                      <p className="font-medium text-gray-900 text-sm">{u.displayName || '—'}</p>
                      <p className="text-xs text-gray-400">{u.email}</p>
                    </td>
                    <td className="px-5 py-3.5 hidden md:table-cell">
                      <p className="text-xs text-gray-500">{fmtDate(u.subscriptionGrantedAt)}</p>
                      {u.subscriptionDurationDays && <p className="text-xs text-gray-400">{u.subscriptionDurationDays} ngày</p>}
                    </td>
                    <td className="px-5 py-3.5 text-center hidden md:table-cell">
                      <p className="text-xs text-gray-600">{fmtDate(u.subscriptionExpiry)}</p>
                    </td>
                    <td className="px-5 py-3.5 text-center">
                      <span className={`text-sm font-semibold ${isActive ? 'text-green-600' : 'text-red-500'}`}>
                        {isActive ? `${days} ngày` : 'Hết hạn'}
                      </span>
                    </td>
                    <td className="px-5 py-3.5 text-right">
                      <span className={`text-sm font-bold ${(u.subscriptionPriceVnd ?? 0) > 0 ? 'text-green-700' : 'text-gray-300'}`}>
                        {(u.subscriptionPriceVnd ?? 0) > 0 ? fmtVnd(u.subscriptionPriceVnd!) : '—'}
                      </span>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
