import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { readSettings } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

function tsToIso(v: unknown): string | null {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  return null;
}

function genShortId(): string {
  return String(Math.floor(100000 + Math.random() * 900000));
}

type Ctx = { params: { uid: string } };

export async function PATCH(req: NextRequest, { params }: Ctx) {
  try {
    const body = await req.json();
    const addMB: number = Number(body.addDataMB) || 0;
    if (addMB <= 0) return NextResponse.json({ ok: true });

    const ref = adminDb.collection('users').doc(params.uid);
    const doc = await ref.get();
    if (!doc.exists) return NextResponse.json({ error: 'not found' }, { status: 404 });

    const current = (doc.data()!.usedDataTodayMB ?? 0) as number;
    await ref.update({ usedDataTodayMB: current + addMB });
    return NextResponse.json({ ok: true, usedDataTodayMB: current + addMB });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function GET(_req: NextRequest, { params }: Ctx) {
  try {
    const ref = adminDb.collection('users').doc(params.uid);
    let doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        uid: params.uid,
        email: '',
        displayName: 'Khách',
        shortId: genShortId(),
        tier: 'free',
        subscriptionStatus: 'free',
        usedDataTodayMB: 0,
        dailyDataLimitMB: 500,
        createdAt: Timestamp.now(),
      });
      doc = await ref.get();
    } else if (!doc.data()!.shortId) {
      // Backfill shortId for existing users that don't have one
      const id = genShortId();
      await ref.update({ shortId: id });
      doc = await ref.get();
    }

    const data = doc.data()!;
    const status = (data.subscriptionStatus ?? data.tier ?? 'free') as string;
    const isVip = status === 'vip';
    const settings = readSettings();
    // Always use the global freeDataLimitMB from admin settings for free users
    const dailyDataLimitMB = isVip
      ? (data.dailyDataLimitMB ?? 999999)
      : settings.freeDataLimitMB;
    return NextResponse.json({
      uid: doc.id,
      shortId: data.shortId ?? '',
      email: data.email ?? '',
      displayName: data.displayName ?? 'Khách',
      subscriptionStatus: isVip ? 'vip' : 'free',
      premiumExpiry: tsToIso(data.premiumExpiry ?? data.subscriptionExpiry),
      dailyDataLimitMB,
      usedDataTodayMB: data.usedDataTodayMB ?? 0,
    });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
