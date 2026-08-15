# HakPay — Release Candidate

Bu paket mevcut HakPay UI'sini koruyarak servis mimarisini toparlanmış bir Android release adayıdır.

## İçeride hazır olanlar

- HakPay ana logo (`assets/hakpay_logo.png`)
- Mevcut ekranlar ve mor/uzay/glass UI
- AuthGate / login
- Görevler, Kazan, Cüzdan, Profil, Çark
- VIP: Bronz / Altın / Elmas
- Abonelik ve erken erişim UI/servisleri
- 1000 puan = 1 TL
- Wallet / withdrawal / transaction servisleri
- Demo + remote backend ayrımı
- Ad session + duplicate claim koruması
- AdMob adaptörü (ID verilmezse DEMO reklam servisi)
- Play Billing adaptörü (ürünler Play Console'da tanımlanınca bağlanabilir)
- Catalog repository: demo mock veya remote API
- Streak / referral servisleri
- CI: `flutter analyze`, test, APK ve AAB üretimi
- Backend URL ve AdMob ID'leri `--dart-define` / GitHub Secrets üzerinden alınır
- Gizli provider secret'ları APK'ya konmaz

## Önemli

Bu kaynak paketinde Flutter'ın otomatik ürettiği `android/` klasörü bulunmaz. CI workflow bunu `flutter create .` ile otomatik üretir. Böylece Android Studio/Flutter sürümüne göre platform dosyaları güncel oluşturulur.

Bu nedenle burada doğrudan hazır bir APK dosyası yoktur. APK/AAB, Flutter ortamında veya GitHub Actions'ta build edilmelidir.

## Hızlı lokal build

```bash
flutter create . --project-name hakpay --org com.hakpay --platforms=android
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release
```

## GitHub'dan APK/AAB

1. ZIP'i açıp GitHub repository'ye yükle.
2. Actions > `HakPay Android Release` > Run workflow.
3. İş tamamlanınca `hakpay-android-release` artifact'ini indir.
4. `app-release.apk` cihaz testleri içindir.
5. Google Play yeni dağıtım için esas olarak `app-release.aab` kullanır.

## Demo / gerçek backend

Backend URL verilmezse uygulama demo modunda çalışır:

`HAKPAY_API_BASE` boş.

Gerçek backend için örnek:

```bash
flutter build apk --release \
  --dart-define=HAKPAY_API_BASE=https://YOUR-API-DOMAIN
```

Sunucu tarafında wallet, withdrawal, offerwall/survey postback, wheel, referral, VIP ve subscription doğrulaması yapılmalıdır.

## AdMob

ID'ler kaynak koda yazılmaz:

```bash
--dart-define=ADMOB_APP_ID=...
--dart-define=ADMOB_REWARDED_ID=...
--dart-define=ADMOB_INTERSTITIAL_ID=...
--dart-define=ADMOB_BANNER_ID=...
```

Önemli: Gerçek para/puan ödülü sadece istemciye güvenilerek verilmemeli. Rewarded reklam/offerwall/anket doğrulaması backend tarafında yapılmalıdır.

## Play Billing

`lib/services/billing_service.dart` içinde adaptör bulunur. VIP/abonelik ürünleri Play Console'da oluşturulduktan sonra gerçek product ID'leri AppConfig'e eklenip satın alma token'ları backend'de doğrulanmalıdır.

## Henüz dış sistem gerektirenler

Kod tarafındaki iskelet hazır olsa da aşağıdakiler hesabın/sağlayıcının bilgileri olmadan gerçek çalışamaz:

- HakPay backend + veritabanı
- AdMob hesabı ve reklam birimleri
- Anket sağlayıcısı + postback
- Offerwall sağlayıcısı + postback
- Google Play Console ürünleri
- Play App Signing / release signing
- Gerçek para çekim/ödeme kuruluşu entegrasyonu
- Firebase/FCM (bildirimler)

Bunlar uygulamanın içine gizli anahtar olarak gömülmemelidir.
