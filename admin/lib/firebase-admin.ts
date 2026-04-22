import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

function getAdminApp(): App {
  if (getApps().length > 0) return getApps()[0];
  const sa = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!sa) throw new Error('FCM_SERVICE_ACCOUNT_JSON not set');
  return initializeApp({ credential: cert(JSON.parse(sa)) });
}

export const adminDb = getFirestore(getAdminApp());
