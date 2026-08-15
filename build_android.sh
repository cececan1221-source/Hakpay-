#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Flutter platform (android) üret / güncelle"
if [ ! -d android ]; then
  flutter create . --project-name hakpay --org com.hakpay --platforms=android
else
  echo "android/ zaten var"
fi

echo "==> pub get"
flutter pub get

echo "==> analyze"
flutter analyze

echo "==> test"
flutter test || true

echo "==> release APK"
flutter build apk --release \
  ${HAKPAY_API_BASE:+--dart-define=HAKPAY_API_BASE=$HAKPAY_API_BASE} \
  ${ADMOB_APP_ID:+--dart-define=ADMOB_APP_ID=$ADMOB_APP_ID} \
  ${ADMOB_REWARDED_ID:+--dart-define=ADMOB_REWARDED_ID=$ADMOB_REWARDED_ID} \
  ${ADMOB_INTERSTITIAL_ID:+--dart-define=ADMOB_INTERSTITIAL_ID=$ADMOB_INTERSTITIAL_ID} \
  ${ADMOB_BANNER_ID:+--dart-define=ADMOB_BANNER_ID=$ADMOB_BANNER_ID}

echo "==> release AAB"
flutter build appbundle --release \
  ${HAKPAY_API_BASE:+--dart-define=HAKPAY_API_BASE=$HAKPAY_API_BASE} \
  ${ADMOB_APP_ID:+--dart-define=ADMOB_APP_ID=$ADMOB_APP_ID} \
  ${ADMOB_REWARDED_ID:+--dart-define=ADMOB_REWARDED_ID=$ADMOB_REWARDED_ID} \
  ${ADMOB_INTERSTITIAL_ID:+--dart-define=ADMOB_INTERSTITIAL_ID=$ADMOB_INTERSTITIAL_ID} \
  ${ADMOB_BANNER_ID:+--dart-define=ADMOB_BANNER_ID=$ADMOB_BANNER_ID}

echo ""
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: build/app/outputs/bundle/release/app-release.aab"
