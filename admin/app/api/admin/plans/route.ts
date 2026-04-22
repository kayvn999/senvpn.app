import { NextRequest, NextResponse } from 'next/server';
import { readPlans, writePlans } from '@/lib/local-store';
import type { VipPlan } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

export async function GET() {
  return NextResponse.json(readPlans());
}

export async function PUT(req: NextRequest) {
  const plans = await req.json() as VipPlan[];
  writePlans(plans);
  return NextResponse.json({ ok: true });
}
