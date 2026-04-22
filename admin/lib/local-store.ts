import fs from 'fs';
import path from 'path';

const DATA_DIR = path.join(process.cwd(), 'data');
const SERVERS_FILE = path.join(DATA_DIR, 'servers.json');
const SETTINGS_FILE = path.join(DATA_DIR, 'settings.json');

function ensureDir() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
}

// ── Types ─────────────────────────────────────────────────────────────────────

export interface VpnServer {
  id: string;
  name: string;
  host: string;
  port: number;
  country: string;
  countryCode: string;
  flag: string;
  protocol: string;
  isActive: boolean;
  isPremium: boolean;
  isFree: boolean;
  load: number;
  ping: number;
  speedMbps: number;
  ovpnConfig: string;
}

export interface AppSettings {
  freeDataLimitMB: number;
  freeMaxConnections: number;
  freeServersPerCountry: number;
  allowedCountries: string[];
  blockedCountries: string[];
  maintenanceMode: boolean;
  maintenanceMessage: string;
  vpngateEnabled: boolean;
  vpngateMaxServers: number;
  oneconnectEnabled: boolean;
  oneconnectApiKey: string;
  oneconnectFreeEnabled: boolean;
  oneconnectProEnabled: boolean;
  oneconnectAllowedCountries: string[];
  storeUrl: string;
  shareText: string;
  privacyPolicyUrl: string;
  termsUrl: string;
  adsEnabled: boolean;
  adIntervalSeconds: number;
  bannerAdUnitAndroid: string;
  bannerAdUnitIos: string;
  interstitialAdUnitAndroid: string;
  interstitialAdUnitIos: string;
  rewardedAdUnitAndroid: string;
  rewardedAdUnitIos: string;
  revenueCatWebhookSecret: string;
}

export const defaultSettings: AppSettings = {
  freeDataLimitMB: 500,
  freeMaxConnections: 1,
  freeServersPerCountry: 10,
  allowedCountries: [],
  blockedCountries: [],
  maintenanceMode: false,
  maintenanceMessage: '',
  vpngateEnabled: true,
  vpngateMaxServers: 500,
  oneconnectEnabled: false,
  oneconnectApiKey: '',
  oneconnectFreeEnabled: true,
  oneconnectProEnabled: true,
  oneconnectAllowedCountries: [],
  storeUrl: '',
  shareText: 'Tải SEN VPN miễn phí tại: ',
  privacyPolicyUrl: '',
  termsUrl: '',
  adsEnabled: false,
  adIntervalSeconds: 180,
  bannerAdUnitAndroid: '',
  bannerAdUnitIos: '',
  interstitialAdUnitAndroid: '',
  interstitialAdUnitIos: '',
  rewardedAdUnitAndroid: '',
  rewardedAdUnitIos: '',
  revenueCatWebhookSecret: '',
};

// ── Servers ───────────────────────────────────────────────────────────────────

export function readServers(): VpnServer[] {
  try {
    if (!fs.existsSync(SERVERS_FILE)) return [];
    return JSON.parse(fs.readFileSync(SERVERS_FILE, 'utf-8')) as VpnServer[];
  } catch { return []; }
}

export function writeServers(servers: VpnServer[]): void {
  ensureDir();
  fs.writeFileSync(SERVERS_FILE, JSON.stringify(servers, null, 2));
}

// ── VIP Plans ─────────────────────────────────────────────────────────────────

export interface VipPlan {
  id: string;
  name: string;
  priceVnd: number;
  currency: string;
  durationDays: number;
  features: string[];
  isActive: boolean;
  isPopular: boolean;
}

const PLANS_FILE = path.join(DATA_DIR, 'plans.json');

const defaultPlans: VipPlan[] = [
  { id: 'weekly',  name: 'Gói tuần',  priceVnd: 29000,  currency: 'VND', durationDays: 7,   features: ['Tất cả server VIP', 'Không giới hạn data', 'Tốc độ cao'], isActive: true, isPopular: false },
  { id: 'monthly', name: 'Gói tháng', priceVnd: 79000,  currency: 'VND', durationDays: 30,  features: ['Tất cả server VIP', 'Không giới hạn data', 'Tốc độ cao', 'Kill Switch', 'DNS bảo mật'], isActive: true, isPopular: true },
  { id: 'yearly',  name: 'Gói năm',   priceVnd: 599000, currency: 'VND', durationDays: 365, features: ['Tất cả server VIP', 'Không giới hạn data', 'Tốc độ cao', 'Kill Switch', 'DNS bảo mật', 'Ưu tiên hỗ trợ'], isActive: true, isPopular: false },
];

export function readPlans(): VipPlan[] {
  try {
    if (!fs.existsSync(PLANS_FILE)) return [...defaultPlans];
    return JSON.parse(fs.readFileSync(PLANS_FILE, 'utf-8')) as VipPlan[];
  } catch { return [...defaultPlans]; }
}

export function writePlans(plans: VipPlan[]): void {
  ensureDir();
  fs.writeFileSync(PLANS_FILE, JSON.stringify(plans, null, 2));
}

// ── Activation Keys ───────────────────────────────────────────────────────────

export interface ActivationKey {
  key: string;
  durationDays: number;
  note: string;
  createdAt: string;
  isUsed: boolean;
  usedAt?: string;
  usedByDeviceId?: string;
}

const KEYS_FILE = path.join(DATA_DIR, 'keys.json');

export function readKeys(): ActivationKey[] {
  try {
    if (!fs.existsSync(KEYS_FILE)) return [];
    return JSON.parse(fs.readFileSync(KEYS_FILE, 'utf-8')) as ActivationKey[];
  } catch { return []; }
}

export function writeKeys(keys: ActivationKey[]): void {
  ensureDir();
  fs.writeFileSync(KEYS_FILE, JSON.stringify(keys, null, 2));
}

const KEY_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function generateKey(): string {
  const rand = (n: number) => Array.from({ length: n }, () => KEY_CHARS[Math.floor(Math.random() * KEY_CHARS.length)]).join('');
  return `SENV-${rand(4)}-${rand(4)}-${rand(4)}`;
}

// ── Settings ──────────────────────────────────────────────────────────────────

export function readSettings(): AppSettings {
  try {
    if (!fs.existsSync(SETTINGS_FILE)) return { ...defaultSettings };
    return { ...defaultSettings, ...JSON.parse(fs.readFileSync(SETTINGS_FILE, 'utf-8')) };
  } catch { return { ...defaultSettings }; }
}

export function writeSettings(settings: AppSettings): void {
  ensureDir();
  fs.writeFileSync(SETTINGS_FILE, JSON.stringify(settings, null, 2));
}
