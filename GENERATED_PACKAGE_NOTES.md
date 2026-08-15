# Bu paket hakkında (üretilmiş kaynak)

Bu klasör, orijinal dokümantasyondaki mimariye göre **sıfırdan kodlanmış** servis katmanı + demo UI kabuğudur.

## Ne kodlandı
- AppConfig (dart-define)
- Result tipi
- ApiClient
- Auth (demo + remote)
- Wallet (creditByReference, çift ödül engeli, hold)
- Withdrawal (hold → pending)
- AdService + AdMob adaptörü
- BillingService (Play Billing + demo VIP)
- CatalogRepository
- Streak / Referral
- Notification soyutlaması
- ServiceLocator
- Demo UI (Kazan, Görevler, Cüzdan, Profil)
- economy_test.dart
- build_android.sh
- GitHub Actions workflow
- Gizlilik / Terms şablonları

## Ne kodlanamaz / dışarıda kalır
- Gerçek backend + DB
- Production AdMob hesabı ID'leri
- Gerçek anket/offerwall postback secret'ları
- Play Console ürün tanımları + imzalama
- Gerçek para çekim kuruluşu
- Orijinal karmaşık GlassCard yatırımcı UI'si (bu pakette sade kabuk var)
- Production fraud / rate limit sunucu tarafı

## Kullanım
```bash
flutter create . --project-name hakpay --org com.hakpay --platforms=android
flutter pub get
flutter run
```
