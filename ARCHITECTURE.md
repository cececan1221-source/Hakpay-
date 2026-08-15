# HakPay MVP Mimari

Mevcut UI (GlassCard, mor/uzay tema, ekranlar) **korunur**.  
Yeni sistemler **servis katmanı** üzerinden bağlanır.

## Klasörler

```
lib/
  config/app_config.dart     # dart-define ile API / AdMob ID
  core/result.dart           # Ok / Err
  services/
    api_client.dart          # HTTP + Bearer token
    auth_service.dart
    wallet_service.dart      # bakiye otoritesi sunucuda
    ad_service.dart          # çift ödül engeli (session id)
    withdrawal_service.dart  # hold + durum makinesi
    callback_verify.dart     # anket/offerwall postback
    service_locator.dart
  ui/legacy_app.dart         # mevcut çalışan UI (bozulmadan)
  main.dart                  # bootstrap
```

## Güvenlik kuralları

| Kural | Uygulama |
|--------|----------|
| Bakiye istemcide otorite değil | `WalletService.credit` miktarı istemciden almaz |
| Çift ödül | `reference_id` / `sessionId` tek kullanımlık |
| API anahtarı APK’da yok | `String.fromEnvironment` / CI secrets |
| Çekim | Önce `hold`, sonra admin onay |
| Anket/oyun | Sadece sunucu verify sonrası puan |

## Backend bağlama

```bash
flutter build apk --release \
  --dart-define=HAKPAY_API_BASE=https://api.senin-domain.com \
  --dart-define=ADMOB_APP_ID=ca-app-pub-xxx \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxx/yyy
```

`HAKPAY_API_BASE` doluysa `Api*` servisleri devreye girer.

## Admin panel (backend)

Ayrı admin API / panel önerilir. Mobil uygulama admin değildir.  
Gerekli endpoint özeti:

- `GET/PATCH /v1/admin/users`
- `GET/PATCH /v1/admin/withdrawals`
- `CRUD /v1/admin/tasks|events|shop|wheel-prizes`
- `POST /v1/admin/banners|announcements`

## Mevcut UI ile birleştirme

1. `legacy_app.dart` içindeki `UserProvider` metodlarında kritik noktalar  
   (`_creditUserPoints`, `purchaseShopProduct`, reklam izleme)  
   `ServiceLocator.I.wallet` / `.ads` / `.withdrawals` çağrısına yönlendirilir.
2. Ekran widget’larına dokunulmaz (renk, GlassCard, navigasyon aynı kalır).
3. Demo modda (`API_BASE` boş) mevcut yatırımcı demosu çalışmaya devam eder.

## Sıradaki entegrasyonlar (API bilgisi gelince)

1. AdMob SDK → `AdService` gerçek implementasyon  
2. Anket sağlayıcı postback → `callback_verify`  
3. Offerwall postback  
4. Play Billing / IAP → VIP & abonelik  
5. FCM → bildirimler  

Sahte “gerçek sistem” yok; arayüzler hazır, sağlayıcı anahtarları bekleniyor.


## Release additions
- `repositories/catalog_repository.dart`: demo/remote catalog boundary.
- `services/admob_ad_service.dart`: AdMob rewarded/interstitial adapter.
- `services/billing_service.dart`: Google Play Billing adapter.
- `services/notification_service.dart`: notification abstraction; FCM can be added without touching UI.
