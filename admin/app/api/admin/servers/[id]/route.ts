import { NextRequest, NextResponse } from 'next/server';
import { readServers, writeServers } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

type Ctx = { params: { id: string } };

export async function PUT(req: NextRequest, { params }: Ctx) {
  const body = await req.json();
  const servers = readServers();
  const idx = servers.findIndex(s => s.id === params.id);
  if (idx === -1) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  servers[idx] = {
    ...servers[idx],
    ...body,
    id: params.id,
    isFree: body.isFree !== undefined ? !!body.isFree : (body.isPremium !== undefined ? !body.isPremium : servers[idx].isFree),
  };
  writeServers(servers);
  return NextResponse.json(servers[idx]);
}

export async function PATCH(req: NextRequest, { params }: Ctx) {
  const { isActive } = await req.json();
  const servers = readServers();
  const idx = servers.findIndex(s => s.id === params.id);
  if (idx === -1) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  servers[idx].isActive = !!isActive;
  writeServers(servers);
  return NextResponse.json(servers[idx]);
}

export async function DELETE(_req: NextRequest, { params }: Ctx) {
  const servers = readServers();
  const idx = servers.findIndex(s => s.id === params.id);
  if (idx === -1) return NextResponse.json({ error: 'Not found' }, { status: 404 });
  servers.splice(idx, 1);
  writeServers(servers);
  return NextResponse.json({ ok: true });
}
