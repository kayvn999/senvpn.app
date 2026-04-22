interface CachedServer {
  id: string; name: string; host: string; port: number;
  protocol: string; country: string; countryCode: string; flag: string;
  ping: number; load: number; isFree: boolean; isVip: boolean;
  isActive: boolean; speedMbps: number; ovpnConfig: string;
}

let _cache: { servers: CachedServer[]; at: number } | null = null;
export const VG_TTL = 30 * 60 * 1000;

export function getCache() { return _cache; }
export function setCache(servers: CachedServer[]) { _cache = { servers, at: Date.now() }; }
export function invalidateCache() { _cache = null; }
export function isCacheValid() { return _cache !== null && Date.now() - _cache.at < VG_TTL; }
export type { CachedServer };
