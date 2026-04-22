import { NextRequest, NextResponse } from 'next/server';
import { readKeys, writeKeys } from '@/lib/local-store';
import { adminDb } from '@/lib/firebase-admin';

export const dynamic = 'force-dynamic';

type Ctx = { params: { key: string } };

// DELETE — xóa key hoàn toàn
export async function DELETE(_req: NextRequest, { params }: Ctx) {
  const keys = readKeys();
  const filtered = keys.filter(k => k.key !== params.key);
  if (filtered.length === keys.length) {
    return NextResponse.json({ error: 'Key not found' }, { status: 404 });
  }
  writeKeys(filtered);
  return NextResponse.json({ ok: true });
}

// POST — hủy kích hoạt key (revoke VIP của user + reset key về chưa dùng)
export async function POST(_req: NextRequest, { params }: Ctx) {
  const keys = readKeys();
  const entry = keys.find(k => k.key === params.key);
  if (!entry) return NextResponse.json({ error: 'Key not found' }, { status: 404 });
  if (!entry.isUsed) return NextResponse.json({ error: 'Key chưa được dùng' }, { status: 400 });

  // Revoke VIP trên Firestore cho user đã dùng key này
  const deviceId = entry.usedByDeviceId;
  if (deviceId) {
    try {
      await adminDb.collection('users').doc(deviceId).update({
        tier: 'free',
        subscriptionStatus: 'free',
        premiumExpiry: null,
        subscriptionExpiry: null,
      });
    } catch (_) {
      // user doc có thể không tồn tại — bỏ qua
    }
  }

  // Reset key về trạng thái chưa dùng
  const updated = keys.map(k =>
    k.key === params.key
      ? { ...k, isUsed: false, usedAt: undefined, usedByDeviceId: undefined }
      : k
  );
  writeKeys(updated);
  return NextResponse.json({ ok: true });
}
