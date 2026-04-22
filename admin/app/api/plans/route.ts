import { NextResponse } from 'next/server';
import { readPlans } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

export async function GET() {
  const plans = readPlans().filter(p => p.isActive);
  return NextResponse.json(plans, { headers: { 'Cache-Control': 'no-store' } });
}
