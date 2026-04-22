import { NextResponse } from 'next/server';
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
        connectedAt: tsToIso(data.connectedAt),
        disconnectedAt: tsToIso(data.disconnectedAt),
        dataMB: data.dataMB ?? null,
      };
    });
    return NextResponse.json(logs);
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
