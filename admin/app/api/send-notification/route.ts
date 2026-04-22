import { NextRequest, NextResponse } from 'next/server';

async function getAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
}): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })).toString('base64url');

  const { createSign } = await import('crypto');
  const sign = createSign('RSA-SHA256');
  sign.update(`${header}.${payload}`);
  const signature = sign.sign(serviceAccount.private_key, 'base64url');
  const jwt = `${header}.${payload}.${signature}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(json.error_description ?? 'Failed to get access token');
  return json.access_token;
}

export async function POST(req: NextRequest) {
  try {
    const { title, body, target } = await req.json();

    if (!title || !body) {
      return NextResponse.json({ error: 'Thiếu title hoặc body' }, { status: 400 });
    }

    const saJson = process.env.FCM_SERVICE_ACCOUNT_JSON;
    if (!saJson) {
      return NextResponse.json(
        { error: 'FCM_SERVICE_ACCOUNT_JSON chưa được cấu hình trong .env.local' },
        { status: 500 }
      );
    }

    const sa = JSON.parse(saJson);
    const projectId = sa.project_id;
    const accessToken = await getAccessToken(sa);

    // Build topic based on target
    let topic = 'all_users';
    if (target === 'vip') topic = 'vip_users';
    if (target === 'free') topic = 'free_users';

    const fcmRes = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            topic,
            notification: { title, body },
            data: { target },
          },
        }),
      }
    );

    const fcmJson = await fcmRes.json();
    if (!fcmRes.ok) {
      return NextResponse.json(
        { error: fcmJson.error?.message ?? 'FCM gửi thất bại' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true, name: fcmJson.name });
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : 'Lỗi server';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
