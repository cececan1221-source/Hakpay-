# HakPay — Tek paket (production-ready kaynak)

Bu klasör **tüm** HakPay kaynaklarını tek yerde toplar.

## Hızlı başlangıç

1. Bu klasörü GitHub reposuna yükle
2. Actions → **HakPay Android Release** → Run workflow
3. Artifact: `hakpay-android-release` (APK + AAB)

veya bilgisayarda:

```bash
bash scripts/build_android.sh
```

## Klasör haritası

```
hakpay_final/
├── lib/
│   ├── main.dart                 # giriş
│   ├── config/app_config.dart    # dart-define (API / AdMob)
│   ├── core/result.dart
│   ├── repositories/             # katalog demo/remote
│   ├── services/                 # wallet, ads, auth, billing...
│   └── ui/legacy_app.dart        # tüm ekranlar (UI bozulmadan)
├── assets/hakpay_logo.png
├── test/economy_test.dart
├── scripts/build_android.sh
├── .github/workflows/build_apk.yml
├── pubspec.yaml
├── ARCHITECTURE.md               # mimari
├── README_RELEASE.md             # release aday özeti
├── RELEASE_READY.md              # checklist
└── RELEASE_REVIEW.md             # inceleme notları
```

## Demo vs gerçek

| Durum | Nasıl |
|--------|--------|
| Demo (şimdi) | `HAKPAY_API_BASE` boş |
| Backend | `--dart-define=HAKPAY_API_BASE=https://...` |
| AdMob | `ADMOB_*` dart-define / GitHub Secrets |

Gizli anahtarlar APK içine **konmaz**.

## Dışarıda tamamlanacaklar

- Backend + DB
- AdMob production ID
- Anket / offerwall postback (sunucu)
- Play Console ürünleri + imzalama
- Gizlilik politikası / mağaza metinleri

Detay: `README_RELEASE.md` ve `RELEASE_READY.md`
