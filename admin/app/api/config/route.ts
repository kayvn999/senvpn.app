import { NextResponse } from 'next/server';
import { readSettings } from '@/lib/local-store';

export const dynamic = 'force-dynamic';

export async function GET() {
  const s = readSettings();
  return NextResponse.json({
    maintenanceMode: s.maintenanceMode,
    maintenanceMessage: s.maintenanceMessage,
    freeDataLimitMB: s.freeDataLimitMB,
    freeMaxConnections: s.freeMaxConnections,
    freeServersPerCountry: s.freeServersPerCountry,
    allowedCountries: s.allowedCountries,
    blockedCountries: s.blockedCountries,
    vpngateEnabled: s.vpngateEnabled,
    vpngateMaxServers: s.vpngateMaxServers,
    oneconnectEnabled: s.oneconnectEnabled,
    oneconnectApiKey: s.oneconnectApiKey,
    oneconnectFreeEnabled: s.oneconnectFreeEnabled,
    oneconnectProEnabled: s.oneconnectProEnabled,
    storeUrl: s.storeUrl,
    shareText: s.shareText,
    privacyPolicyUrl: s.privacyPolicyUrl,
    termsUrl: s.termsUrl,
    adsEnabled: s.adsEnabled,
    adIntervalSeconds: s.adIntervalSeconds,
    bannerAdUnitAndroid: s.bannerAdUnitAndroid,
    bannerAdUnitIos: s.bannerAdUnitIos,
    interstitialAdUnitAndroid: s.interstitialAdUnitAndroid,
    interstitialAdUnitIos: s.interstitialAdUnitIos,
    rewardedAdUnitAndroid: s.rewardedAdUnitAndroid,
    rewardedAdUnitIos: s.rewardedAdUnitIos,
  });
}
