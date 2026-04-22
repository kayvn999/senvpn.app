import { NextRequest, NextResponse } from 'next/server';
import { adminDb } from '@/lib/firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { readSettings } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

const GRANT_EVENTS = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'NON_RENEWING_PURCHASE',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
  'BILLING_ISSUE_RESOLVED',
]);

const REVOKE_EVENTS = new Set([
  'EXPIRATION',
  'CANCELLATION',
]);

function durationDaysFromProductId(productId: string): number {
  if (productId.includes('weekly')) return 7;
  if (productId.includes('yearly') || productId.includes('annual')) return 365;
  return 30; // monthly default
}

export async function POST(req: NextRequest) {
  try {
    const settings = readSettings();
    const secret = settings.revenueCatWebhookSecret ?? '';

    // Validate authorization
    if (secret) {
      const auth = req.headers.get('authorization') ?? '';
      const token = auth.startsWith('Bearer ') ? auth.slice(7) : auth;
      if (token !== secret) {
        return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
      }
    }

    const body = await req.json();
    const event = body?.event;
    if (!event) return NextResponse.json({ ok: true });

    const eventType: string = event.type ?? '';
    const appUserId: string = event.app_user_id ?? event.original_app_user_id ?? '';
    const productId: string = event.product_id ?? '';
    const expirationMs: number | null = event.expiration_at_ms ?? null;

    if (!appUserId) return NextResponse.json({ ok: true });

    const ref = adminDb.collection('users').doc(appUserId);

    if (GRANT_EVENTS.has(eventType)) {
      let expiry: Date;
      if (expirationMs) {
        expiry = new Date(expirationMs);
      } else {
        const days = durationDaysFromProductId(productId);
        expiry = new Date();
        expiry.setDate(expiry.getDate() + days);
      }
      const ts = Timestamp.fromDate(expiry);
      await ref.set({
        tier: 'vip',
        subscriptionStatus: 'vip',
        premiumExpiry: ts,
        subscriptionExpiry: ts,
        subscriptionGrantedAt: Timestamp.now(),
        rcProductId: productId,
        rcEventType: eventType,
      }, { merge: true });
    } else if (REVOKE_EVENTS.has(eventType)) {
      await ref.set({
        tier: 'free',
        subscriptionStatus: 'free',
        premiumExpiry: null,
        subscriptionExpiry: null,
        rcEventType: eventType,
      }, { merge: true });
    }

    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error('RC webhook error:', e);
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
