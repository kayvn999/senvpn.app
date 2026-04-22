'use client';

import { useEffect, useState, useCallback } from 'react';
import ServerModal from '@/components/ServerModal';

export interface VpnServer {
  id: string;
  name: string;
  host: string;
  port: number;
  country: string;
  countryCode: string;
  flag: string;
  protocol: string;
  isActive: boolean;
  isPremium: boolean;
  isFree: boolean;
  load: number;
  ping: number;
  speedMbps: number;
  ovpnConfig: string;
}

export default function ServersPage() {
  const [servers, setServers] = useState<VpnServer[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filterActive, setFilterActive] = useState<'all' | 'active' | 'inactive'>('all');
  const [filterType, setFilterType] = useState<'all' | 'free' | 'premium'>('all');
  const [modalOpen, setModalOpen] = useState(false);
  const [editingServer, setEditingServer] = useState<VpnServer | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [togglingId, setTogglingId] = useState<string | null>(null);
  const [error, setError] = useState('');

  const loadServers = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const res = await fetch('/api/admin/servers');
      if (!res.ok) throw new Error(await res.text());
      setServers(await res.json());
    } catch (e) {
      setError('Không thể tải danh sách máy chủ.');
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadServers(); }, [loadServers]);

  const handleDelete = async (id: string) => {
    if (!confirm('Bạn có chắc chắn muốn xóa máy chủ này?')) return;
    setDeletingId(id);
    try {
      const res = await fetch(`/api/admin/servers/${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error(await res.text());
      setServers(prev => prev.filter(s => s.id !== id));
    } catch (e) {
      setError('Lỗi khi xóa máy chủ.');
      console.error(e);
    } finally {
      setDeletingId(null);
    }
  };

  const handleToggle = async (server: VpnServer) => {
    setTogglingId(server.id);
    try {
      const res = await fetch(`/api/admin/servers/${server.id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isActive: !server.isActive }),
      });
      if (!res.ok) throw new Error(await res.text());
      setServers(prev =>
        prev.map(s => s.id === server.id ? { ...s, isActive: !s.isActive } : s)
      );
    } catch (e) {
      setError('Lỗi khi cập nhật trạng thái.');
      console.error(e);
    } finally {
      setTogglingId(null);
    }
  };

  const filtered = servers.filter(s => {
    const matchSearch =
      !search ||
      s.name.toLowerCase().includes(search.toLowerCase()) ||
      s.host.toLowerCase().includes(search.toLowerCase()) ||
      s.country.toLowerCase().includes(search.toLowerCase()) ||
      s.countryCode.toLowerCase().includes(search.toLowerCase());
    const matchActive =
      filterActive === 'all' ||
      (filterActive === 'active' && s.isActive) ||
      (filterActive === 'inactive' && !s.isActive);
    const matchType =
      filterType === 'all' ||
      (filterType === 'premium' && s.isPremium) ||
      (filterType === 'free' && !s.isPremium);
    return matchSearch && matchActive && matchType;
  });

  return (
    <div>
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Máy chủ VPN</h1>
          <p className="text-sm text-gray-500 mt-1">
            {servers.length} máy chủ &bull; {servers.filter(s => s.isActive).length} đang hoạt động
          </p>
        </div>
        <button
          onClick={() => { setEditingServer(null); setModalOpen(true); }}
          className="flex items-center gap-2 px-4 py-2.5 bg-indigo-500 hover:bg-indigo-600 text-white text-sm font-semibold rounded-xl transition-colors"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Thêm máy chủ
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl border border-gray-100 p-4 mb-4">
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Tìm theo tên, IP, quốc gia..."
              className="w-full pl-9 pr-4 py-2 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>
          <select
            value={filterActive}
            onChange={e => setFilterActive(e.target.value as typeof filterActive)}
            className="px-3 py-2 border border-gray-200 rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="active">Đang hoạt động</option>
            <option value="inactive">Đã tắt</option>
          </select>
          <select
            value={filterType}
            onChange={e => setFilterType(e.target.value as typeof filterType)}
            className="px-3 py-2 border border-gray-200 rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            <option value="all">Tất cả loại</option>
            <option value="free">Free</option>
            <option value="premium">VIP</option>
          </select>
        </div>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">{error}</div>
      )}

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-500" />
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center">
            <svg className="w-12 h-12 text-gray-200 mx-auto mb-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M5.25 14.25h13.5m-13.5 0a3 3 0 01-3-3m3 3a3 3 0 003 3h10.5a3 3 0 003-3m-16.5 0V6.75m0 7.5V6.75m0 0a3 3 0 013-3h10.5a3 3 0 013 3m0 7.5V6.75" />
            </svg>
            <p className="text-sm text-gray-500 font-medium">Không tìm thấy máy chủ nào</p>
            <p className="text-xs text-gray-400 mt-1">Thử thay đổi bộ lọc hoặc thêm máy chủ mới</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Tên / Host</th>
                  <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden md:table-cell">Quốc gia</th>
                  <th className="text-left px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide hidden lg:table-cell">Giao thức</th>
                  <th className="text-center px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Loại</th>
                  <th className="text-center px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Trạng thái</th>
                  <th className="text-right px-5 py-3.5 text-xs font-semibold text-gray-500 uppercase tracking-wide">Hành động</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {filtered.map(server => (
                  <tr key={server.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-4">
                      <p className="font-semibold text-gray-900">{server.name}</p>
                      <code className="text-xs text-gray-400 font-mono">{server.host}:{server.port}</code>
                    </td>
                    <td className="px-5 py-4 hidden md:table-cell">
                      <span className="font-medium text-gray-700">{server.flag} {server.country}</span>
                      <span className="ml-1 text-xs text-gray-400">({server.countryCode})</span>
                    </td>
                    <td className="px-5 py-4 hidden lg:table-cell">
                      <span className="text-xs bg-blue-50 text-blue-700 px-2 py-1 rounded-full font-medium">{server.protocol}</span>
                    </td>
                    <td className="px-5 py-4 text-center">
                      {server.isPremium ? (
                        <span className="text-xs px-2.5 py-1 rounded-full font-semibold bg-yellow-100 text-yellow-700">VIP</span>
                      ) : (
                        <span className="text-xs px-2.5 py-1 rounded-full font-semibold bg-gray-100 text-gray-600">Free</span>
                      )}
                    </td>
                    <td className="px-5 py-4 text-center">
                      <button
                        onClick={() => handleToggle(server)}
                        disabled={togglingId === server.id}
                        className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors disabled:opacity-50 ${
                          server.isActive ? 'bg-green-500' : 'bg-gray-300'
                        }`}
                      >
                        <span
                          className="inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-sm transition-transform"
                          style={{ transform: server.isActive ? 'translateX(18px)' : 'translateX(2px)' }}
                        />
                      </button>
                    </td>
                    <td className="px-5 py-4 text-right">
                      <div className="flex items-center justify-end gap-1">
                        <button
                          onClick={() => { setEditingServer(server); setModalOpen(true); }}
                          className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                          title="Chỉnh sửa"
                        >
                          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                            <path strokeLinecap="round" strokeLinejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L10.582 16.07a4.5 4.5 0 01-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 011.13-1.897l8.932-8.931zm0 0L19.5 7.125" />
                          </svg>
                        </button>
                        <button
                          onClick={() => handleDelete(server.id)}
                          disabled={deletingId === server.id}
                          className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50"
                          title="Xóa"
                        >
                          {deletingId === server.id ? (
                            <div className="animate-spin h-4 w-4 border-b-2 border-red-500 rounded-full" />
                          ) : (
                            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                              <path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                            </svg>
                          )}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        {!loading && filtered.length > 0 && (
          <div className="px-5 py-3 border-t border-gray-50 text-xs text-gray-400">
            Hiển thị {filtered.length} / {servers.length} máy chủ
          </div>
        )}
      </div>

      {modalOpen && (
        <ServerModal
          server={editingServer}
          onClose={() => setModalOpen(false)}
          onSaved={loadServers}
        />
      )}
    </div>
  );
}
