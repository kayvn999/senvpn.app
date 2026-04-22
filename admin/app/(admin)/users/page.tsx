'use client';

import { useEffect, useState } from 'react';

interface ApiUser {
  uid: string;
  shortId: string;
  email: string;
  displayName: string;
  tier: 'free' | 'vip';
  subscriptionExpiry: string | null;
  subscriptionGrantedAt: string | null;
  subscriptionDurationDays?: number;
  subscriptionPriceVnd?: number;
  createdAt: string | null;
  usedDataTodayMB: number;
}

function formatDate(iso: string | null) {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString('vi-VN');
}

function isExpired(iso: string | null) {
  if (!iso) return true;
  return new Date(iso) < new Date();
}

export default function UsersPage() {
  const [users, setUsers] = useState<ApiUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'vip' | 'free'>('all');
  const [grantingUid, setGrantingUid] = useState<string | null>(null);
  const [daysInput, setDaysInput] = useState<Record<string, number>>({});
  const [priceInput, setPriceInput] = useState<Record<string, number>>({});

  const load = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/users');
      if (!res.ok) throw new Error();
      setUsers(await res.json());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  const filtered = users.filter((u) => {
    const matchSearch =
      u.email.toLowerCase().includes(search.toLowerCase()) ||
      u.displayName.toLowerCase().includes(search.toLowerCase()) ||
      u.shortId.includes(search);
    const matchFilter =
      filter === 'all' ||
      (filter === 'vip' && u.tier === 'vip') ||
      (filter === 'free' && u.tier === 'free');
    return matchSearch && matchFilter;
  });

  const handleGrant = async (uid: string) => {
    const days = daysInput[uid] ?? 30;
    const price = priceInput[uid] ?? 0;
    if (!confirm(`Cấp VIP ${days} ngày cho tài khoản này?`)) return;
    setGrantingUid(uid);
    try {
      await fetch(`/api/admin/users/${uid}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'grant', durationDays: days, priceVnd: price }),
      });
      await load();
    } finally {
      setGrantingUid(null);
    }
  };

  const handleRevoke = async (uid: string) => {
    if (!confirm('Thu hồi VIP của tài khoản này?')) return;
    setGrantingUid(uid);
    try {
      await fetch(`/api/admin/users/${uid}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'revoke' }),
      });
      await load();
    } finally {
      setGrantingUid(null);
    }
  };

  const handleDelete = async (uid: string) => {
    if (!confirm('Xóa tài khoản này khỏi hệ thống?')) return;
    setGrantingUid(uid);
    try {
      await fetch(`/api/admin/users/${uid}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'delete' }),
      });
      await load();
    } finally {
      setGrantingUid(null);
    }
  };

  const vipCount = users.filter((u) => u.tier === 'vip').length;
  const freeCount = users.length - vipCount;

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Người dùng</h1>
        <p className="text-sm text-gray-500 mt-1">Quản lý tài khoản và cấp quyền VIP</p>
      </div>

      <div className="grid grid-cols-3 gap-4 mb-6">
        {[
          { label: 'Tổng', value: users.length, color: 'bg-indigo-50 text-indigo-600' },
          { label: 'VIP', value: vipCount, color: 'bg-yellow-50 text-yellow-600' },
          { label: 'Free', value: freeCount, color: 'bg-gray-50 text-gray-600' },
        ].map((s) => (
          <div key={s.label} className={`${s.color} rounded-2xl p-4 text-center`}>
            <p className="text-2xl font-bold">{s.value}</p>
            <p className="text-xs font-medium mt-0.5 opacity-70">{s.label}</p>
          </div>
        ))}
      </div>

      <div className="flex flex-col sm:flex-row gap-3 mb-5">
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Tìm theo email hoặc tên..."
          className="flex-1 px-4 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
        />
        <div className="flex gap-2">
          {(['all', 'vip', 'free'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition-colors ${
                filter === f ? 'bg-indigo-600 text-white' : 'bg-white border border-gray-200 text-gray-600 hover:bg-gray-50'
              }`}
            >
              {f === 'all' ? 'Tất cả' : f === 'vip' ? 'VIP' : 'Free'}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="space-y-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="bg-white rounded-2xl border border-gray-100 p-5 animate-pulse">
              <div className="h-4 bg-gray-100 rounded w-48 mb-2" />
              <div className="h-3 bg-gray-100 rounded w-32" />
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
          {filtered.length === 0 ? (
            <div className="p-10 text-center text-gray-400 text-sm">Không tìm thấy tài khoản nào.</div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-100">
                  <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Tài khoản</th>
                  <th className="text-center px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Gói</th>
                  <th className="text-center px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Hết hạn</th>
                  <th className="text-right px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map((user) => {
                  const expired = isExpired(user.subscriptionExpiry);
                  const isLoading = grantingUid === user.uid;
                  return (
                    <tr key={user.uid} className="hover:bg-gray-50 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-9 h-9 rounded-full bg-indigo-100 flex items-center justify-center flex-shrink-0">
                            <span className="text-sm font-bold text-indigo-600">
                              {user.displayName?.charAt(0)?.toUpperCase() || user.email?.charAt(0)?.toUpperCase() || '?'}
                            </span>
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <p className="font-semibold text-gray-900">{user.displayName || '(ẩn danh)'}</p>
                              {user.shortId && (
                                <span className="text-xs font-mono bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded">
                                  #{user.shortId}
                                </span>
                              )}
                            </div>
                            <p className="text-xs text-gray-400">{user.email || 'Khách ẩn danh'}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4 text-center">
                        <span className={`text-xs px-2.5 py-1 rounded-full font-semibold ${
                          user.tier === 'vip' && !expired ? 'bg-yellow-100 text-yellow-700' : 'bg-gray-100 text-gray-500'
                        }`}>
                          {user.tier === 'vip' && !expired ? '⭐ VIP' : 'Free'}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-center hidden md:table-cell">
                        <span className={`text-xs ${user.tier === 'vip' && !expired ? 'text-green-600 font-medium' : 'text-gray-400'}`}>
                          {user.tier === 'vip' ? formatDate(user.subscriptionExpiry) : '—'}
                        </span>
                      </td>
                      <td className="px-5 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => handleDelete(user.uid)}
                            disabled={isLoading}
                            className="px-2 py-1.5 text-xs font-semibold rounded-lg bg-gray-50 text-gray-400 hover:bg-red-50 hover:text-red-500 disabled:opacity-50 transition-colors"
                            title="Xóa tài khoản"
                          >
                            🗑
                          </button>
                          {user.tier === 'vip' && !expired ? (
                            <button
                              onClick={() => handleRevoke(user.uid)}
                              disabled={isLoading}
                              className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-red-50 text-red-600 hover:bg-red-100 disabled:opacity-50 transition-colors"
                            >
                              {isLoading ? '...' : 'Thu hồi VIP'}
                            </button>
                          ) : (
                            <div className="flex items-center gap-1.5">
                              <input
                                type="number" min={1} max={365}
                                value={daysInput[user.uid] ?? 30}
                                onChange={(e) => setDaysInput((prev) => ({ ...prev, [user.uid]: Number(e.target.value) }))}
                                className="w-14 px-2 py-1.5 text-xs rounded-lg border border-gray-200 text-center focus:outline-none focus:ring-2 focus:ring-indigo-300"
                                title="Số ngày VIP"
                              />
                              <span className="text-xs text-gray-400">ngày</span>
                              <input
                                type="number" min={0}
                                value={priceInput[user.uid] ?? 0}
                                onChange={(e) => setPriceInput((prev) => ({ ...prev, [user.uid]: Number(e.target.value) }))}
                                className="w-20 px-2 py-1.5 text-xs rounded-lg border border-gray-200 text-center focus:outline-none focus:ring-2 focus:ring-indigo-300"
                                title="Giá (VNĐ)"
                              />
                              <span className="text-xs text-gray-400">₫</span>
                              <button
                                onClick={() => handleGrant(user.uid)}
                                disabled={isLoading}
                                className="px-3 py-1.5 text-xs font-semibold rounded-lg bg-yellow-50 text-yellow-700 hover:bg-yellow-100 disabled:opacity-50 transition-colors"
                              >
                                {isLoading ? '...' : 'Cấp VIP'}
                              </button>
                            </div>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}
