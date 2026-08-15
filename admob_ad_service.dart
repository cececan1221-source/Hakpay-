import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import '../core/result.dart';
import 'ad_service.dart';
import 'api_client.dart';
import 'wallet_service.dart';

/// AdMob rewarded / interstitial adaptörü.
/// ID verilmezse test birimleri kullanılır.
class AdMobAdService implements AdService {
  AdMobAdService({
    required this.inner, // session + claim mantığı (demo veya remote)
  });

  final AdService inner;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    await _loadRewarded();
    await _loadInterstitial();
  }

  Future<void> _loadRewarded() async {
    await RewardedAd.load(
      adUnitId: AppConfig.effectiveRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  Future<void> _loadInterstitial() async {
    await InterstitialAd.load(
      adUnitId: AppConfig.effectiveInterstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  @override
  Future<Result<AdSession>> openSession({String adType = 'rewarded'}) =>
      inner.openSession(adType: adType);

  @override
  Future<Result<int>> claim(String sessionId) => inner.claim(sessionId);

  @override
  Future<bool> showRewarded() async {
    await initialize();
    final ad = _rewarded;
    if (ad == null) {
      await _loadRewarded();
      return false;
    }
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _rewarded = null;
        _loadRewarded();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) {
      earned = true;
    });
    // Güvenlik zaman aşımı (reklam UI kilitlenmesin)
    return completer.future.timeout(
      const Duration(seconds: 120),
      onTimeout: () => earned,
    );
  }

  @override
  Future<bool> showInterstitial() async {
    await initialize();
    final ad = _interstitial;
    if (ad == null) {
      await _loadInterstitial();
      return false;
    }
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _interstitial = null;
        _loadInterstitial();
      },
    );
    ad.show();
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Future<Result<int>> runTripleAdCycle() async {
    var total = 0;
    for (var i = 0; i < 3; i++) {
      final session = await openSession(adType: 'rewarded');
      if (session.isErr) return Err(session.errorOrNull!);
      final shown = await showRewarded();
      if (!shown) return Err('Reklam ${i + 1}/3 gösterilemedi');
      final claimed = await claim(session.valueOrNull!.sessionId);
      if (claimed.isErr) return Err(claimed.errorOrNull!);
      total += claimed.valueOrNull ?? 0;
    }
    return Ok(total);
  }
}

/// Factory: mümkünse AdMob sarmalayıcı, yoksa düz demo/remote.
AdService createAdMobAwareAdService(
  ApiClient? api,
  WalletService wallet,
) {
  final base = AppConfig.isRemote && api != null
      ? RemoteAdService(api, () async => false, () async => false)
      : DemoAdService(wallet);

  // AdMob her zaman denenebilir (test ID ile)
  return AdMobAdService(inner: base);
}
