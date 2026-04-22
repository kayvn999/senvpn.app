import { NextRequest, NextResponse } from 'next/server';
import { readServers, writeServers } from '@/lib/local-store';
import type { VpnServer } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

function flag(code: string): string {
  try {
    return String.fromCodePoint(
      ...code.toUpperCase().split('').map(c => 0x1F1E6 + c.charCodeAt(0) - 65)
    );
  } catch { return '🌍'; }
}

export async function GET() {
  return NextResponse.json(readServers());
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const servers = readServers();
  const id = `s_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
  const server: VpnServer = {
    id,
    name: body.name ?? '',
    host: body.host ?? '',
    port: Number(body.port ?? 1194),
    country: body.country ?? '',
    countryCode: body.countryCode ?? '',
    flag: body.flag || flag(body.countryCode ?? ''),
    protocol: body.protocol ?? 'OpenVPN',
    isActive: body.isActive !== false,
    isPremium: !!body.isPremium,
    isFree: body.isFree ?? !body.isPremium,
    load: Number(body.load ?? 0),
    ping: Number(body.ping ?? 99),
    speedMbps: Number(body.speedMbps ?? 100),
    ovpnConfig: body.ovpnConfig ?? '',
  };
  servers.push(server);
  writeServers(servers);
  return NextResponse.json(server, { status: 201 });
}
