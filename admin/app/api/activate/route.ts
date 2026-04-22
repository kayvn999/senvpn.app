import { NextRequest, NextResponse } from 'next/server';
import { readKeys, writeKeys } from '@/lib/local-store';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { key, deviceId } = await req.json();

    if (!key || !deviceId) {
      return NextResponse.json({ error: 'Thiếu thông tin.' }, { status: 400 });
    }

    const normalized = String(key).trim().toUpperCase();
    const keys = readKeys();
    const idx = keys.findIndex(k => k.key === normalized);

    if (idx === -1) {
      return NextResponse.json({ error: 'Mã kích hoạt không hợp lệ.' }, { status: 404 });
    }

    const entry = keys[idx];

    if (entry.isUsed) {
      return NextResponse.json({ error: 'Mã này đã được sử dụng rồi.' }, { status: 409 });
    }

    // Grant VIP in Firestore
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + entry.durationDays);
    const ts = Timestamp.fromDate(expiry);

    const ref = adminDb.collection('users').doc(deviceId);
    const doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        uid: deviceId,
        email: '',
        displayName: 'Khách',
        shortId: String(Math.floor(100000 + Math.random() * 900000)),
        tier: 'vip',
        subscriptionStatus: 'vip',
        premiumExpiry: ts,
        subscriptionExpiry: ts,
        usedDataTodayMB: 0,
        dailyDataLimitMB: 500,
        createdAt: Timestamp.now(),
        activatedByKey: normalized,
      });
    } else {
      await ref.update({
        tier: 'vip',
        subscriptionStatus: 'vip',
        premiumExpiry: ts,
        subscriptionExpiry: ts,
        activatedByKey: normalized,
        keyActivatedAt: Timestamp.now(),
      });
    }

    // Mark key as used
    keys[idx] = {
      ...entry,
      isUsed: true,
      usedAt: new Date().toISOString(),
      usedByDeviceId: deviceId,
    };
    writeKeys(keys);

    return NextResponse.json({
      ok: true,
      durationDays: entry.durationDays,
      expiresAt: expiry.toISOString(),
    });
  } catch (e) {
    console.error('[/api/activate]', e);
    return NextResponse.json({ error: 'Lỗi máy chủ, vui lòng thử lại.' }, { status: 500 });
  }
}
