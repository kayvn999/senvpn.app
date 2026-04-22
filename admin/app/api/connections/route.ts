import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';

export const dynamic = 'force-dynamic';

// POST /api/connections/log
// Flutter app sends connection logs here instead of writing to Firestore directly
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { uid, email, serverName, serverCountry, action, connectedAt, disconnectedAt, dataMB } = body;

    if (!uid || !action) {
      return NextResponse.json({ error: 'Missing uid or action' }, { status: 400 });
    }

    if (action === 'start') {
      // Log connection start
      const ref = await adminDb.collection('connections').add({
        uid,
        email: email || '',
        serverName: serverName || '',
        serverCountry: serverCountry || '',
        connectedAt: Timestamp.now(),
      });
      return NextResponse.json({ ok: true, id: ref.id });
    } else if (action === 'end') {
      // Log connection end
      const { logId } = body;
      if (!logId) {
        return NextResponse.json({ error: 'Missing logId for end action' }, { status: 400 });
      }
      await adminDb.collection('connections').doc(logId).update({
        disconnectedAt: Timestamp.now(),
        dataMB: dataMB || 0,
      });
      return NextResponse.json({ ok: true });
    } else {
      return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
    }
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

// GET /api/connections
// Admin panel reads connection logs via this endpoint
export async function GET() {
  try {
    const snap = await adminDb.collection('connections')
      .orderBy('connectedAt', 'desc')
      .limit(200)
      .get();
    const logs = snap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        uid: data.uid ?? '',
        email: data.email ?? '',
        serverName: data.serverName ?? '',
        serverCountry: data.serverCountry ?? '',
        connectedAt: data.connectedAt ? data.connectedAt.toDate().toISOString() : null,
        disconnectedAt: data.disconnectedAt ? data.disconnectedAt.toDate().toISOString() : null,
        dataMB: data.dataMB ?? null,
      };
    });
    return NextResponse.json(logs);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
