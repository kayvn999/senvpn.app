import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  try {
    const { uid, displayName, email } = await req.json();
    if (!uid) return NextResponse.json({ error: 'uid required' }, { status: 400 });

    const ref = adminDb.collection('users').doc(uid);
    const doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        uid,
        email: email ?? '',
        displayName: displayName ?? 'Khách',
        tier: 'free',
        subscriptionStatus: 'free',
        usedDataTodayMB: 0,
        createdAt: Timestamp.now(),
      });
    }
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
