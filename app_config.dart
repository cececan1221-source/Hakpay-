/// HakPay uygulama yapılandırması.
/// Tüm gizli / ortam değerleri --dart-define ile gelir.
/// APK içine secret gömülmez.
class AppConfig {
  AppConfig._();

  /// Backend taban URL. Boşsa demo mod.
  static const String apiBase = String.fromEnvironment(
    'HAKPAY_API_BASE',
    defaultValue: '',
  );

  static bool get isDemo => apiBase.trim().isEmpty;
  static bool get isRemote => !isDemo;

  // AdMob — production ID'ler dart-define ile verilir.
  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: '',
  );

  static const String admobRewardedId = String.fromEnvironment(
    'ADMOB_REWARDED_ID',
    defaultValue: '',
  );

  static const String admobInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ID',
    defaultValue: '',
  );

  static const String admobBannerId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: '',
  );

  static const String testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testBannerId =
      'ca-app-pub-3940256099942544/6300978111';

  static String get effectiveRewardedId =>
      admobRewardedId.isNotEmpty ? admobRewardedId : testRewardedId;

  static String get effectiveInterstitialId =>
      admobInterstitialId.isNotEmpty ? admobInterstitialId : testInterstitialId;

  static String get effectiveBannerId =>
      admobBannerId.isNotEmpty ? admobBannerId : testBannerId;

  static bool get hasProductionAds =>
      admobAppId.isNotEmpty && admobRewardedId.isNotEmpty;

  static const String vipBronzeId = String.fromEnvironment(
    'IAP_VIP_BRONZE',
    defaultValue: 'hakpay_vip_bronze',
  );
  static const String vipGoldId = String.fromEnvironment(
    'IAP_VIP_GOLD',
    defaultValue: 'hakpay_vip_gold',
  );
  static const String vipDiamondId = String.fromEnvironment(
    'IAP_VIP_DIAMOND',
    defaultValue: 'hakpay_vip_diamond',
  );
  static const String subscriptionMonthlyId = String.fromEnvironment(
    'IAP_SUB_MONTHLY',
    defaultValue: 'hakpay_sub_monthly',
  );

  /// 1000 puan = 1 TL = 1 Sikke / UC eşdeğeri
  static const int pointsPerTl = 1000;

  static double pointsToTl(int points) => points / pointsPerTl;
  static int tlToPoints(double tl) => (tl * pointsPerTl).round();

  // ─── MVP Ekonomi (Kapalı Test) ───────────────────────
  /// Üçlü reklam döngüsü toplam ödül (3 reklam = 60 puan ≈ 6 kuruş)
  static const int tripleAdCyclePoints = 60;
  /// Tek reklam ödülü (döngü / 3)
  static const int singleAdPoints = 20;

  /// Anket / offerwall: brüt kazancın kullanıcıya yansıyan oranı (%35)
  static const double offerwallUserShare = 0.35;

  /// Erken erişim bonus puanı
  static const int earlyAccessBonusPoints = 5000;

  /// Mağaza — Paradox Manga sikkesi paketleri (nakit yok)
  static const int shopPack80kPoints = 80000;
  static const int shopPack150kPoints = 150000;

  /// Nakit çekim MVP'de kapalı
  static const bool cashWithdrawalEnabled = false;
}
