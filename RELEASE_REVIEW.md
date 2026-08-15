# HakPay — Release Review Package

Bu paket, gönderilen Flutter MVP'nin incelenebilir temizlenmiş kopyasıdır.

## Bu sürümde yapılanlar
- Verilen ana HakPay logosu `assets/hakpay_logo.png` olarak eklendi.
- Flutter proje adı `hakpay_app` olarak güncellendi.
- Ana UI'daki eski `Haiku` marka/metinleri `HakPay` olarak temizlendi.
- `haiku.app` örnek e-posta adresleri `hakpay.app` olarak güncellendi.
- `.dart_tool` ve Flutter tarafından üretilen yerel dosyalar paketten çıkarıldı.
- Demo/mock mimarisi korunmuştur.

## Önemli
Bu ZIP'te `android/` klasörü kaynak ZIP'te bulunmadığı için Android release projesi henüz dahil değildir.
Bu nedenle bu paket tek başına final APK üretmeye hazır bir Android proje arşivi değildir.

Gerçek backend, AdMob, Play Billing, survey/offerwall postback ve gerçek ödeme altyapısı da bu pakette aktif değildir; mevcut servis iskeleti/demolar korunmuştur.

## Sonraki teknik kontrol
1. Android platform klasörünü gerçek Flutter projesinden doğrula.
2. `flutter pub get`
3. `flutter analyze`
4. `flutter test`
5. Gerçek Android cihazda demo akışlarını test et.
6. Release APK/AAB üret.
