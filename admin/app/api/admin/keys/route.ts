import { NextRequest, NextResponse } from 'next/server';
import { readKeys, writeKeys, generateKey, ActivationKey } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

export async function GET() {
  const keys = readKeys();
  keys.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  return NextResponse.json(keys);
}

export async function POST(req: NextRequest) {
  const { durationDays, note, count } = await req.json();
  const days = Number(durationDays ?? 30);
  const qty = Math.min(Number(count ?? 1), 100); // max 100 at once

  const existing = readKeys();
  const created: ActivationKey[] = [];

  for (let i = 0; i < qty; i++) {
    let key: string;
    const existingKeys = new Set(existing.map(k => k.key));
    do { key = generateKey(); } while (existingKeys.has(key));

    const entry: ActivationKey = {
      key,
      durationDays: days,
      note: note ?? '',
      createdAt: new Date().toISOString(),
      isUsed: false,
    };
    existing.push(entry);
    created.push(entry);
  }

  writeKeys(existing);
  return NextResponse.json({ ok: true, created });
}
