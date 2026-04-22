import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

export const dynamic = 'force-dynamic';

function tsToIso(v: unknown): string | null {
  if (!v) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  return null;
}

export async function GET() {
  try {
    const snap = await adminDb.collection('notifications')
      .orderBy('sentAt', 'desc')
      .limit(50)
      .get();
    const logs = snap.docs.map((d) => {
      const data = d.data();
      return { id: d.id, title: data.title ?? '', body: data.body ?? '', target: data.target ?? 'all', sentAt: tsToIso(data.sentAt) };
    });
    return NextResponse.json(logs);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const { title, body, target } = await req.json();
    await adminDb.collection('notifications').add({ title, body, target, sentAt: Timestamp.now() });
    return NextResponse.json({ ok: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
