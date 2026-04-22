import { NextResponse } from 'next/server';
import { readServers, readSettings } from '@/lib/local-store';
import { adminDb } from '@/lib/firebase-admin';

export const dynamic = 'force-dynamic';
import { Timestamp } from 'firebase-admin/firestore';

function toNum(v: unknown, fallback = 0): number {
  const n = Number(v);
  return isNaN(n) ? fallback : n;
}

export async function GET() {
  try {
    const [servers, settings, usersSnap] = await Promise.all([
      Promise.resolve(readServers()),
      Promise.resolve(readSettings()),
      adminDb.collection('users').get(),
    ]);

    const users = usersSnap.docs.map(d => d.data());
    const vipUsers = users.filter(u => (u.subscriptionStatus ?? u.tier ?? '') === 'vip').length;

    const now = new Date();
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const revenueThisMonth = users.reduce((sum, u) => {
      const grantedAt = u.subscriptionGrantedAt as Timestamp | undefined;
      if (!grantedAt) return sum;
      if (grantedAt.toDate() >= monthStart) return sum + toNum(u.subscriptionPriceVnd);
      return sum;
    }, 0);

    return NextResponse.json({
      totalUsers: users.length,
      vipUsers,
      freeUsers: users.length - vipUsers,
      totalServers: servers.length,
      activeServers: servers.filter(s => s.isActive).length,
      maintenanceMode: settings.maintenanceMode,
      revenueThisMonth,
    });
  } catch (e) {
    console.error('[/api/admin/stats]', e);
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
