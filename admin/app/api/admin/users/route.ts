import { NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

export const dynamic = 'force-dynamic';

function tsToIso(v: unknown): string | null {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  return null;
}

function toNum(v: unknown, fb = 0): number {
  const n = Number(v); return isNaN(n) ? fb : n;
}

export async function GET() {
  try {
    const snap = await adminDb.collection('users').get();
    const users = snap.docs.map((d) => {
      const data = d.data();
      const status = (data.subscriptionStatus ?? data.tier ?? 'free') as string;
      return {
        uid: d.id,
        shortId: data.shortId ?? '',
        email: data.email ?? '',
        displayName: data.displayName ?? '',
        tier: status === 'vip' ? 'vip' : 'free',
        subscriptionExpiry: tsToIso(data.premiumExpiry ?? data.subscriptionExpiry),
        subscriptionGrantedAt: tsToIso(data.subscriptionGrantedAt),
        subscriptionDurationDays: data.subscriptionDurationDays ? toNum(data.subscriptionDurationDays) : undefined,
        subscriptionPriceVnd: data.subscriptionPriceVnd ? toNum(data.subscriptionPriceVnd) : undefined,
        createdAt: tsToIso(data.createdAt),
        usedDataTodayMB: toNum(data.usedDataTodayMB),
      };
    });
    return NextResponse.json(users);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
