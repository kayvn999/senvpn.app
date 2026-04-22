'use client';

import { useEffect, useState } from 'react';
import type { VipPlan } from '@/lib/local-store';

// Fixed plan types — must match RevenueCat PackageType
const PLAN_TYPES = [
  { id: 'weekly',  label: '1 tuần',  durationDays: 7 },
  { id: 'monthly', label: '1 tháng', durationDays: 30 },
  { id: 'yearly',  label: '1 năm',   durationDays: 365 },
] as const;

type PlanTypeId = typeof PLAN_TYPES[number]['id'];

const emptyPlan = (): Omit<VipPlan, 'id'> & { planType: PlanTypeId } => ({
  name: '',
  priceVnd: 0,
  currency: 'VND',
  durationDays: 30,
  features: [''],
  isActive: true,
  isPopular: false,
  planType: 'monthly',
});

export default function PlansPage() {
  const [plans, setPlans] = useState<VipPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState('');
  const [modalPlan, setModalPlan] = useState<{ index: number | null; data: Omit<VipPlan, 'id'> & { planType: PlanTypeId } } | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const res = await fetch('/api/admin/plans');
        if (!res.ok) throw new Error();
        setPlans(await res.json());
      } catch {
        setError('Không thể tải gói VIP.');
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const openAdd = () => setModalPlan({ index: null, data: emptyPlan() });
  const openEdit = (i: number) => {
    const pt = PLAN_TYPES.find(p => p.id === plans[i].id) ?? PLAN_TYPES[1];
    setModalPlan({
      index: i,
      data: {
        name: plans[i].name,
        priceVnd: plans[i].priceVnd,
        currency: plans[i].currency ?? 'VND',
        durationDays: pt.durationDays,
        features: [...plans[i].features],
        isActive: plans[i].isActive,
        isPopular: plans[i].isPopular ?? false,
        planType: pt.id,
      },
    });
  };

  const savePlans = async (updated: VipPlan[]) => {
    setSaving(true);
    setError('');
    try {
      const res = await fetch('/api/admin/plans', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updated),
      });
      if (!res.ok) throw new Error();
      setPlans(updated);
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } catch {
      setError('Lưu thất bại. Vui lòng thử lại.');
    } finally {
      setSaving(false);
    }
  };

  const handleModalSave = () => {
    if (!modalPlan) return;
    const pt = PLAN_TYPES.find(p => p.id === modalPlan.data.planType) ?? PLAN_TYPES[1];
    const newPlan: VipPlan = {
      id: pt.id,
      name: modalPlan.data.name,
      priceVnd: modalPlan.data.priceVnd,
      currency: modalPlan.data.currency,
      durationDays: pt.durationDays,
      features: modalPlan.data.features.filter((f) => f.trim()),
      isActive: modalPlan.data.isActive,
      isPopular: modalPlan.data.isPopular,
    };
    // prevent duplicate plan type
    const filtered = modalPlan.index !== null
      ? plans.filter((_, i) => i !== modalPlan.index)
      : plans;
    const alreadyExists = filtered.some(p => p.id === pt.id);
    if (alreadyExists) {
      alert(`Đã tồn tại gói "${pt.label}". Mỗi loại chỉ được có 1 gói.`);
      return;
    }
    const updated = modalPlan.index !== null
      ? plans.map((p, i) => (i === modalPlan.index ? newPlan : p))
      : [...plans, newPlan];
    setModalPlan(null);
    savePlans(updated);
  };

  const handleDelete = (i: number) => {
    if (!confirm('Xóa gói này?')) return;
    savePlans(plans.filter((_, idx) => idx !== i));
  };

  const handleToggleActive = (i: number) => {
    const updated = plans.map((p, idx) =>
      idx === i ? { ...p, isActive: !p.isActive } : p
    );
    savePlans(updated);
  };

  const setFeature = (i: number, val: string) => {
    if (!modalPlan) return;
    const features = [...modalPlan.data.features];
    features[i] = val;
    setModalPlan({ ...modalPlan, data: { ...modalPlan.data, features } });
  };

  const addFeature = () => {
    if (!modalPlan) return;
    setModalPlan({ ...modalPlan, data: { ...modalPlan.data, features: [...modalPlan.data.features, ''] } });
  };

  const removeFeature = (i: number) => {
    if (!modalPlan) return;
    setModalPlan({
      ...modalPlan,
      data: { ...modalPlan.data, features: modalPlan.data.features.filter((_, idx) => idx !== i) },
    });
  };

  const durationLabel = (d: number) => {
    if (d === 7) return '1 tuần';
    if (d === 30) return '1 tháng';
    if (d === 90) return '3 tháng';
    if (d === 365) return '1 năm';
    return `${d} ngày`;
  };

  const priceVndLabel = (p: number, currency = 'VND') =>
    `${p.toLocaleString('vi-VN')} ${currency}`;

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Gói VIP</h1>
          <p className="text-sm text-gray-500 mt-1">Quản lý các gói đăng ký VIP cho người dùng</p>
        </div>
        <button
          onClick={openAdd}
          className="flex items-center gap-2 px-4 py-2.5 bg-yellow-500 text-white rounded-xl text-sm font-semibold hover:bg-yellow-600 transition-colors"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Thêm gói
        </button>
      </div>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">{error}</div>
      )}
      {saved && (
        <div className="mb-4 bg-green-50 border border-green-200 rounded-xl px-4 py-3 text-sm text-green-700 flex items-center gap-2">
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Đã lưu thành công!
        </div>
      )}

      {/* Modal */}
      {modalPlan && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-md max-h-[90vh] flex flex-col">
            <div className="px-6 py-5 border-b border-gray-100 flex items-center justify-between">
              <h2 className="text-lg font-bold text-gray-900">
                {modalPlan.index !== null ? 'Chỉnh sửa gói' : 'Thêm gói mới'}
              </h2>
              <button onClick={() => setModalPlan(null)} className="text-gray-400 hover:text-gray-600">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <div className="flex-1 overflow-y-auto px-6 py-5 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Tên gói</label>
                <input
                  value={modalPlan.data.name}
                  onChange={(e) => setModalPlan({ ...modalPlan, data: { ...modalPlan.data, name: e.target.value } })}
                  placeholder="vd: Gói tháng"
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-yellow-300"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Loại gói (RevenueCat)</label>
                <select
                  value={modalPlan.data.planType}
                  onChange={(e) => setModalPlan({ ...modalPlan, data: { ...modalPlan.data, planType: e.target.value as PlanTypeId } })}
                  className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-yellow-300"
                >
                  {PLAN_TYPES.map((pt) => (
                    <option key={pt.id} value={pt.id}>{pt.label} ({pt.id})</option>
                  ))}
                </select>
                <p className="text-xs text-gray-400 mt-1">Phải khớp với Product ID trên Google Play & RevenueCat</p>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Giá hiển thị</label>
                  <input
                    type="number"
                    value={modalPlan.data.priceVnd}
                    onChange={(e) => setModalPlan({ ...modalPlan, data: { ...modalPlan.data, priceVnd: Number(e.target.value) } })}
                    className="w-full px-3 py-2.5 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-yellow-300"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Tiền tệ</label>
                  <select
                    value={modalPlan.data.currency ?? 'VND'}
                    onChange={(e) => setModalPlan({ ...modalPlan, data: { ...modalPlan.data, currency: e.target.value } })}
                    className="w-full px-2 py-2.5 rounded-xl border border-gray-200 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-yellow-300"
                  >
                    <option value="VND">VND</option>
                    <option value="USD">USD</option>
                  </select>
                </div>
              </div>

              <div>
                <div className="flex items-center justify-between mb-2">
                  <label className="text-sm font-medium text-gray-700">Tính năng</label>
                  <button
                    type="button"
                    onClick={addFeature}
                    className="text-xs text-yellow-600 hover:text-yellow-700 font-semibold"
                  >
                    + Thêm
                  </button>
                </div>
                <div className="space-y-2">
                  {modalPlan.data.features.map((f, i) => (
                    <div key={i} className="flex gap-2">
                      <input
                        value={f}
                        onChange={(e) => setFeature(i, e.target.value)}
                        placeholder={`Tính năng ${i + 1}`}
                        className="flex-1 px-3 py-2 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-yellow-300"
                      />
                      <button
                        type="button"
                        onClick={() => removeFeature(i)}
                        className="p-2 text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg"
                      >
                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                          <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                    </div>
                  ))}
                </div>
              </div>

              <div className="space-y-2">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={modalPlan.data.isActive}
                    onChange={(e) => setModalPlan({ ...modalPlan, data: { ...modalPlan.data, isActive: e.target.checked } })}
                    className="w-4 h-4 accent-yellow-500"
                  />
                  <span className="text-sm text-gray-700">Kích hoạt gói này</span>
                </label>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={modalPlan.data.isPopular ?? false}
                    onChange={(e) => setModalPlan({ ...modalPlan, data: { ...modalPlan.data, isPopular: e.target.checked } })}
                    className="w-4 h-4 accent-orange-500"
                  />
                  <span className="text-sm text-gray-700">🔥 Đánh dấu là <strong>Phổ biến</strong> (hiện badge trên app)</span>
                </label>
              </div>
            </div>

            <div className="px-6 py-4 border-t border-gray-100 flex gap-3">
              <button
                onClick={() => setModalPlan(null)}
                className="flex-1 px-4 py-2.5 rounded-xl border border-gray-200 text-sm font-medium text-gray-600 hover:bg-gray-50"
              >
                Hủy
              </button>
              <button
                onClick={handleModalSave}
                disabled={saving || !modalPlan.data.name.trim()}
                className="flex-1 px-4 py-2.5 rounded-xl bg-yellow-500 text-white text-sm font-semibold hover:bg-yellow-600 disabled:opacity-60"
              >
                {saving ? 'Đang lưu...' : 'Lưu'}
              </button>
            </div>
          </div>
        </div>
      )}

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="bg-white rounded-2xl border border-gray-100 p-6 animate-pulse h-48" />
          ))}
        </div>
      ) : plans.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 p-12 text-center">
          <div className="w-14 h-14 bg-yellow-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <svg className="w-7 h-7 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
            </svg>
          </div>
          <p className="text-gray-500 text-sm">Chưa có gói VIP. Nhấn &quot;Thêm gói&quot; để tạo mới.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {plans.map((plan, i) => (
            <div
              key={plan.id}
              className={`bg-white rounded-2xl border p-6 relative ${
                plan.isActive ? 'border-gray-100' : 'border-dashed border-gray-200 opacity-60'
              }`}
            >
              {plan.isPopular && (
                <span className="absolute top-3 right-3 text-xs bg-orange-100 text-orange-600 px-2 py-0.5 rounded-full font-semibold">
                  🔥 Phổ biến
                </span>
              )}
              {!plan.isActive && !plan.isPopular && (
                <span className="absolute top-3 right-3 text-xs bg-gray-100 text-gray-500 px-2 py-0.5 rounded-full font-medium">
                  Tắt
                </span>
              )}

              <div className="mb-4">
                <p className="text-xs font-semibold text-yellow-600 uppercase tracking-wide mb-1">
                  {durationLabel(plan.durationDays)}
                </p>
                <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
                <p className="text-2xl font-extrabold text-yellow-500 mt-1">{priceVndLabel(plan.priceVnd, (plan as VipPlan & { currency?: string }).currency)}</p>
              </div>

              <ul className="space-y-1.5 mb-5">
                {plan.features.map((f, fi) => (
                  <li key={fi} className="flex items-center gap-2 text-sm text-gray-600">
                    <svg className="w-4 h-4 text-green-500 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                    </svg>
                    {f}
                  </li>
                ))}
              </ul>

              <div className="flex gap-2 pt-4 border-t border-gray-100">
                <button
                  onClick={() => handleToggleActive(i)}
                  className={`flex-1 py-2 rounded-xl text-xs font-semibold transition-colors ${
                    plan.isActive
                      ? 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                      : 'bg-green-50 text-green-600 hover:bg-green-100'
                  }`}
                >
                  {plan.isActive ? 'Tắt' : 'Bật'}
                </button>
                <button
                  onClick={() => openEdit(i)}
                  className="flex-1 py-2 rounded-xl bg-indigo-50 text-indigo-600 text-xs font-semibold hover:bg-indigo-100 transition-colors"
                >
                  Sửa
                </button>
                <button
                  onClick={() => handleDelete(i)}
                  className="py-2 px-3 rounded-xl bg-red-50 text-red-500 text-xs font-semibold hover:bg-red-100 transition-colors"
                >
                  Xóa
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
