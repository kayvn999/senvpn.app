import { NextResponse } from 'next/server';
import { readServers, readSettings } from '@/lib/local-store';
import { getCache, setCache, isCacheValid, type CachedServer } from '@/lib/vpngate-cache';

export const dynamic = 'force-dynamic';

// ── Types ───────────────────────────────────────────────────────────────────
type PublicServer = CachedServer & { vpnUsername?: string; vpnPassword?: string };

// Try HTTP first (faster on most VPS), then HTTPS as fallback
const VG_URLS = [
  'http://www.vpngate.net/api/iphone/',
  'https://www.vpngate.net/api/iphone/',
];

function flag(code: string): string {
  try {
    return String.fromCodePoint(
      ...code.toUpperCase().split('').map(c => 0x1F1E6 + c.charCodeAt(0) - 65)
    );
  } catch { return '🌍'; }
}

async function fetchVpnGateRaw(): Promise<string | null> {
  for (const url of VG_URLS) {
    try {
      const resp = await fetch(url, {
        headers: { 'User-Agent': 'Mozilla/5.0 SecureVPN/1.0' },
        signal: AbortSignal.timeout(25000),
      });
      if (resp.ok) {
        const text = await resp.text();
        if (text.length > 2000) return text;
      }
    } catch { /* try next URL */ }
  }
  return null;
}

function parseVpnGate(
  csv: string,
  maxTotal: number,
  maxPerCountry: number,
  blockedSet: Set<string>,
  allowedSet: Set<string>,
): PublicServer[] {
  const servers: PublicServer[] = [];
  const cnt: Record<string, number> = {};

  for (const line of csv.split('\n')) {
    if (line.startsWith('*') || line.startsWith('#') || !line.trim()) continue;
    const cols = line.split(',');
    if (cols.length <= 14) continue;
    try {
      const cc = cols[6].toUpperCase().trim();
      if (cc.length !== 2) continue;
      if (blockedSet.has(cc)) continue;
      if (allowedSet.size > 0 && !allowedSet.has(cc)) continue;

      const n = cnt[cc] ?? 0;
      if (n >= maxPerCountry) continue;

      const ip = cols[1].trim();
      if (!ip) continue;

      const ovpnBase64 = cols[14].trim();
      let ovpnConfig: string;
      try { ovpnConfig = Buffer.from(ovpnBase64, 'base64').toString('utf-8'); }
      catch { continue; }
      if (!ovpnConfig || !ovpnConfig.includes('client')) continue;

      const ping = parseInt(cols[3]) || 999;
      const speedBps = parseInt(cols[4]) || 0;
      const sessions = parseInt(cols[7]) || 0;
      const raw = cols[5].trim();
      const country = raw ? (raw.charAt(0).toUpperCase() + raw.slice(1).toLowerCase()) : 'Unknown';
      const name = n === 0 ? country : `${country} #${n + 1}`;

      servers.push({
        id: `vg_${ip}_${cc}`, name, host: ip, port: 1194,
        protocol: 'OpenVPN', country, countryCode: cc, flag: flag(cc),
        ping, load: Math.min(100, Math.round(sessions / 20)),
        isFree: true, isVip: false, isActive: true,
        speedMbps: speedBps / 1_000_000, ovpnConfig,
      });

      cnt[cc] = n + 1;
      if (servers.length >= maxTotal) break;
    } catch { continue; }
  }

  servers.sort((a, b) => a.ping - b.ping);
  return servers;
}

async function fetchVpnGate(
  maxTotal: number,
  maxPerCountry: number,
  blocked: string[],
  allowed: string[],
): Promise<PublicServer[]> {
  if (isCacheValid()) return getCache()!.servers;

  try {
    const csv = await fetchVpnGateRaw();
    if (!csv) return getCache()?.servers ?? [];

    const blockedSet = new Set(blocked.map(c => c.toUpperCase()));
    const allowedSet = new Set(allowed.map(c => c.toUpperCase()));
    const servers = parseVpnGate(csv, maxTotal, maxPerCountry, blockedSet, allowedSet);

    setCache(servers);
    console.log(`[VPNGate] fetched ${servers.length} servers from ${new Set(servers.map(s => s.countryCode)).size} countries`);
    return servers;
  } catch (e) {
    console.error('[VPNGate] fetch error:', e);
    return getCache()?.servers ?? [];
  }
}

// ── OneConnect ───────────────────────────────────────────────────────────────
async function fetchOneConnect(
  apiKey: string,
  freeEnabled: boolean,
  proEnabled: boolean,
  allowedCountries: string[],
  blockedSet: Set<string>,
): Promise<PublicServer[]> {
  const servers: PublicServer[] = [];
  const types = [
    ...(freeEnabled ? ['free'] : []),
    ...(proEnabled ? ['pro'] : []),
  ];

  for (const type of types) {
    try {
      const res = await fetch('https://developer.oneconnect.top/api/v1/servers', {
        headers: { 'Authorization': `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ type }),
        method: 'POST',
        signal: AbortSignal.timeout(15000),
      });
      if (!res.ok) continue;
      const data = await res.json();
      const list = Array.isArray(data) ? data : (data.data ?? data.servers ?? []);
      for (const s of list) {
        const cc = (s.country_code ?? s.countryCode ?? '').toUpperCase();
        if (blockedSet.has(cc)) continue;
        if (allowedCountries.length > 0 && !allowedCountries.includes(cc)) continue;
        if (!s.ovpn_config && !s.ovpnConfig) continue;
        servers.push({
          id: `oc_${s.id ?? s.server_id ?? Math.random()}`,
          name: s.country ?? s.name ?? 'Unknown',
          host: s.ip ?? s.host ?? '',
          port: s.port ?? 1194,
          protocol: 'OpenVPN',
          country: s.country ?? '',
          countryCode: cc,
          flag: cc.length === 2 ? flag(cc) : '🌍',
          ping: s.ping ?? 99,
          load: s.load ?? 0,
          isFree: type === 'free',
          isVip: type === 'pro',
          isActive: true,
          speedMbps: s.speed ?? 100,
          ovpnConfig: s.ovpn_config ?? s.ovpnConfig ?? '',
          vpnUsername: s.username ?? s.vpn_username ?? '',
          vpnPassword: s.password ?? s.vpn_password ?? '',
        });
      }
    } catch { continue; }
  }
  return servers;
}

// ── GET /api/servers ─────────────────────────────────────────────────────────
export async function GET() {
  try {
    const cfg = readSettings();

    const localServers: PublicServer[] = readServers()
      .filter(s => s.isActive)
      .map(s => ({
        id: s.id, name: s.name, host: s.host, port: s.port,
        protocol: s.protocol, country: s.country, countryCode: s.countryCode,
        flag: s.flag || flag(s.countryCode),
        ping: s.ping, load: s.load,
        isFree: s.isFree, isVip: s.isPremium,
        isActive: true, speedMbps: s.speedMbps, ovpnConfig: s.ovpnConfig,
      }));

    const blockedSet = new Set(cfg.blockedCountries.map(c => c.toUpperCase()));

    const vpngateServers = cfg.vpngateEnabled
      ? await fetchVpnGate(
          cfg.vpngateMaxServers,
          cfg.freeServersPerCountry,
          cfg.blockedCountries,
          cfg.allowedCountries,
        )
      : [];

    const oneconnectServers = cfg.oneconnectEnabled && cfg.oneconnectApiKey
      ? await fetchOneConnect(
          cfg.oneconnectApiKey,
          cfg.oneconnectFreeEnabled ?? true,
          cfg.oneconnectProEnabled ?? true,
          cfg.oneconnectAllowedCountries ?? [],
          blockedSet,
        )
      : [];

    const hostsSeen = new Set(localServers.map(s => s.host));
    const merged = [
      ...localServers,
      ...vpngateServers.filter(s => !hostsSeen.has(s.host)),
      ...oneconnectServers.filter(s => !hostsSeen.has(s.host)),
    ].sort((a, b) => a.ping - b.ping);

    return NextResponse.json(merged, {
      headers: { 'Cache-Control': 'no-store' },
    });
  } catch (e) {
    console.error('[/api/servers]', e);
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
