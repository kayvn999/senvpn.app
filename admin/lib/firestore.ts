import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  setDoc,
  query,
  orderBy,
  limit,
  Timestamp,
  DocumentData,
} from 'firebase/firestore';
import { db } from './firebase';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function toBool(v: unknown): boolean {
  if (typeof v === 'boolean') return v;
  if (typeof v === 'string') return v === 'true' || v === '1';
  return Boolean(v);
}

function toNum(v: unknown, fallback = 0): number {
  const n = Number(v);
  return isNaN(n) ? fallback : n;
}


// Flutter writes subscriptionStatus ('free'|'vip'|'expired'), older records use tier.
// Admin normalises to tier for internal display.
function normalizeUser(id: string, data: DocumentData): AppUser {
  const status = (data.subscriptionStatus ?? data.tier ?? 'free') as string;
  const tier: 'free' | 'vip' = status === 'vip' ? 'vip' : 'free';
  return {
    uid: id,
    email: data.email ?? '',
    displayName: data.displayName ?? '',
    tier,
    subscriptionExpiry: data.premiumExpiry ?? data.subscriptionExpiry ?? null,
    subscriptionGrantedAt: data.subscriptionGrantedAt ?? null,
    subscriptionDurationDays: data.subscriptionDurationDays ? toNum(data.subscriptionDurationDays) : undefined,
    subscriptionPriceVnd: data.subscriptionPriceVnd ? toNum(data.subscriptionPriceVnd) : undefined,
    createdAt: data.createdAt,
    usedDataTodayMB: toNum(data.usedDataTodayMB),
  };
}

// ─── Types ────────────────────────────────────────────────────────────────────


export interface AppUser {
  uid?: string;
  email: string;
  displayName: string;
  tier: 'free' | 'vip';
  subscriptionExpiry?: Timestamp | null;
  subscriptionGrantedAt?: Timestamp | null;
  subscriptionDurationDays?: number;
  subscriptionPriceVnd?: number;
  createdAt?: Timestamp;
  usedDataTodayMB?: number;
}

export interface AppVersion {
  version: string;
  buildNumber: number;
  forceUpdate: boolean;
  minVersion: string;
  releaseNotes: string;
  downloadUrl: string;
  updatedAt?: Timestamp;
}

export interface ConnectionLog {
  id?: string;
  uid: string;
  email?: string;
  serverName: string;
  serverCountry: string;
  connectedAt: Timestamp;
  disconnectedAt?: Timestamp;
  dataMB?: number;
}

export interface NotificationPayload {
  title: string;
  body: string;
  target: 'all' | 'vip' | 'free';
}

export interface DashboardStats {
  totalUsers: number;
  vipUsers: number;
  freeUsers: number;
  totalServers: number;
  activeServers: number;
  maintenanceMode: boolean;
  revenueThisMonth: number;
}



// ─── Users ────────────────────────────────────────────────────────────────────

export async function getUsers(): Promise<AppUser[]> {
  const snapshot = await getDocs(collection(db, 'users'));
  return snapshot.docs.map((d) => normalizeUser(d.id, d.data()));
}

export async function grantVip(uid: string, durationDays: number, priceVnd = 0): Promise<void> {
  const expiry = new Date();
  expiry.setDate(expiry.getDate() + durationDays);
  const expiryTs = Timestamp.fromDate(expiry);
  // Write all field variants so both Flutter app and admin panel stay in sync
  await updateDoc(doc(db, 'users', uid), {
    tier: 'vip',
    subscriptionStatus: 'vip',
    subscriptionExpiry: expiryTs,
    premiumExpiry: expiryTs,
    subscriptionGrantedAt: Timestamp.now(),
    subscriptionDurationDays: durationDays,
    subscriptionPriceVnd: priceVnd,
  });
}

export async function revokeVip(uid: string): Promise<void> {
  await updateDoc(doc(db, 'users', uid), {
    tier: 'free',
    subscriptionStatus: 'free',
    subscriptionExpiry: null,
    premiumExpiry: null,
  });
}

// ─── App Version ──────────────────────────────────────────────────────────────

export async function getAppVersion(): Promise<AppVersion> {
  const snap = await getDoc(doc(db, 'app_config', 'app_version'));
  if (snap.exists()) return snap.data() as AppVersion;
  return {
    version: '1.0.0',
    buildNumber: 1,
    forceUpdate: false,
    minVersion: '1.0.0',
    releaseNotes: '',
    downloadUrl: '',
  };
}

export async function saveAppVersion(data: AppVersion): Promise<void> {
  await setDoc(doc(db, 'app_config', 'app_version'), {
    ...data,
    updatedAt: Timestamp.now(),
  });
}

// ─── Connection History ───────────────────────────────────────────────────────

export async function getConnectionLogs(limitCount = 100): Promise<ConnectionLog[]> {
  try {
    const q = query(
      collection(db, 'connections'),
      orderBy('connectedAt', 'desc'),
      limit(limitCount)
    );
    const snap = await getDocs(q);
    return snap.docs.map((d) => ({ id: d.id, ...d.data() } as ConnectionLog));
  } catch {
    return [];
  }
}

// ─── Notifications ────────────────────────────────────────────────────────────

export async function saveNotificationLog(payload: NotificationPayload): Promise<void> {
  await addDoc(collection(db, 'notifications'), {
    ...payload,
    sentAt: Timestamp.now(),
  });
}

export interface NotificationLog {
  id?: string;
  title: string;
  body: string;
  target: string;
  sentAt: Timestamp;
}

export async function getNotificationLogs(): Promise<NotificationLog[]> {
  try {
    const q = query(collection(db, 'notifications'), orderBy('sentAt', 'desc'), limit(50));
    const snap = await getDocs(q);
    return snap.docs.map((d) => ({ id: d.id, ...d.data() } as NotificationLog));
  } catch {
    return [];
  }
}

// ─── Admin Check ──────────────────────────────────────────────────────────────

export async function isAdmin(email: string): Promise<boolean> {
  if (!email) return false;
  const snap = await getDoc(doc(db, 'admins', email));
  return snap.exists();
}

// ─── Dashboard Stats ──────────────────────────────────────────────────────────

