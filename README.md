# HakPay

Görev tamamla, puan kazan. **1000 puan = 1 TL.**

Bu paket: servis katmanı + demo UI kabuğu + CI + release script.

## Hızlı başlangıç

```bash
# Android platform yoksa üret
flutter create . --project-name hakpay --org com.hakpay --platforms=android

flutter pub get
flutter run
```

Demo giriş: `demo@hakpay.app` / `demo1234`

## Gerçek backend

```bash
flutter run --dart-define=HAKPAY_API_BASE=https://api.senin-domain.com
```

## Release build

```bash
bash scripts/build_android.sh
```

veya GitHub Actions → **HakPay Android Release**.

## Mimari

- `lib/config/app_config.dart` — dart-define
- `lib/services/` — wallet, ads, auth, billing, withdrawal...
- `lib/repositories/catalog_repository.dart`
- `lib/ui/legacy_app.dart` — servisleri kullanan UI kabuğu

**Güvenlik:** Bakiye istemcide otorite değil. Çift ödül `reference_id` ile engellenir. Secret APK’da yok.

## Dışarıda kalanlar

Backend, AdMob production ID, Play Console ürünleri, gerçek çekim, gizlilik politikası (şablonlar `docs/` altında).

Detay: `ARCHITECTURE.md`, `RELEASE_READY.md`
