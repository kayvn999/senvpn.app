import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

export const dynamic = 'force-dynamic';

type Ctx = { params: { uid: string } };

export async function POST(req: NextRequest, { params }: Ctx) {
  try {
    const { action, durationDays, priceVnd } = await req.json();
    const ref = adminDb.collection('users').doc(params.uid);

    if (action === 'grant') {
      const days = Number(durationDays ?? 30);
      const expiry = new Date();
      expiry.setDate(expiry.getDate() + days);
      const ts = Timestamp.fromDate(expiry);
      await ref.update({
        tier: 'vip',
        subscriptionStatus: 'vip',
        subscriptionExpiry: ts,
        premiumExpiry: ts,
        subscriptionGrantedAt: Timestamp.now(),
        subscriptionDurationDays: days,
        subscriptionPriceVnd: Number(priceVnd ?? 0),
      });
      return NextResponse.json({ ok: true });
    }

    if (action === 'revoke') {
      await ref.update({
        tier: 'free',
        subscriptionStatus: 'free',
        subscriptionExpiry: null,
        premiumExpiry: null,
      });
      return NextResponse.json({ ok: true });
    }

    if (action === 'delete') {
      await ref.delete();
      return NextResponse.json({ ok: true });
    }

    return NextResponse.json({ error: 'Unknown action' }, { status: 400 });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
