import { NextRequest, NextResponse } from 'next/server';
import { readSettings, writeSettings } from '@/lib/local-store';
import { invalidateCache } from '@/lib/vpngate-cache';

export const dynamic = 'force-dynamic';

export async function GET() {
  return NextResponse.json(readSettings());
}

export async function PUT(req: NextRequest) {
  const body = await req.json();
  writeSettings(body);
  // Invalidate VPNGate cache so country filters take effect immediately
  invalidateCache();
  return NextResponse.json({ ok: true });
}
