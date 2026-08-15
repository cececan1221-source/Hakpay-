import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../core/result.dart';
import 'api_client.dart';
import 'wallet_service.dart';

/// Reklam oturumu — çift ödül engeli için sessionId / referenceId.
class AdSession {
  final String sessionId;
  final String adType; // rewarded | interstitial
  final DateTime createdAt;

  const AdSession({
    required this.sessionId,
    required this.adType,
    required this.createdAt,
  });
}

/// Ad sınırı.
/// 1) openSession → sessionId al
/// 2) reklam izlet
/// 3) claim(sessionId) → sunucu doğrular, puan yazar
abstract class AdService {
  Future<Result<AdSession>> openSession({String adType = 'rewarded'});
  Future<Result<int>> claim(String sessionId);
  Future<bool> showRewarded();
  Future<bool> showInterstitial();

  /// Üçlü reklam döngüsü (3×20 = 60 puan).
  Future<Result<int>> runTripleAdCycle();
}

/// Demo: gerçek reklam yok, hemen başarılı sayılır.
class DemoAdService implements AdService {
  final WalletService _wallet;
  final _uuid = const Uuid();
  final _open = <String, AdSession>{};
  final _claimed = <String>{};

  DemoAdService(this._wallet);

  @override
  Future<Result<AdSession>> openSession({String adType = 'rewarded'}) async {
    final s = AdSession(
      sessionId: _uuid.v4(),
      adType: adType,
      createdAt: DateTime.now(),
    );
    _open[s.sessionId] = s;
    return Ok(s);
  }

  @override
  Future<Result<int>> claim(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      return const Err('Geçersiz oturum kimliği');
    }
    if (!_open.containsKey(sessionId)) {
      return const Err('Geçersiz veya süresi dolmuş oturum');
    }
    if (_claimed.contains(sessionId)) {
      return const Err('Bu oturum zaten kullanıldı');
    }
    // Önce credit; başarısızsa oturum yanmasın
    final credit = await _wallet.creditByReference(
      referenceId: sessionId,
      reason: 'ad_reward',
    );
    if (credit.isErr) return Err(credit.errorOrNull!);
    _claimed.add(sessionId);
    return Ok(AppConfig.singleAdPoints);
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

  @override
  Future<bool> showRewarded() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }

  @override
  Future<bool> showInterstitial() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

/// Remote: session sunucudan, claim sunucuya.
/// Gerçek AdMob gösterimi [AdMobAdService] üzerinden yapılır.
class RemoteAdService implements AdService {
  RemoteAdService(this._api, this._showRewarded, this._showInterstitial);
  final ApiClient _api;
  final Future<bool> Function() _showRewarded;
  final Future<bool> Function() _showInterstitial;

  @override
  Future<Result<AdSession>> openSession({String adType = 'rewarded'}) async {
    final res = await _api.post('/v1/ads/session', body: {'ad_type': adType});
    return res.when(
      ok: (d) {
        final sid = d['session_id']?.toString().trim() ?? '';
        if (sid.isEmpty) {
          return const Err('Sunucu geçersiz session_id döndü');
        }
        return Ok(AdSession(
          sessionId: sid,
          adType: adType,
          createdAt: DateTime.now(),
        ));
      },
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<int>> claim(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      return const Err('Geçersiz oturum kimliği');
    }
    final res = await _api.post('/v1/ads/claim', body: {
      'session_id': sessionId.trim(),
    });
    return res.when(
      ok: (d) => Ok((d['points'] as num?)?.toInt() ?? 0),
      err: (m) => Err(m),
    );
  }

  @override
  Future<bool> showRewarded() => _showRewarded();

  @override
  Future<bool> showInterstitial() => _showInterstitial();

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

AdService createAdService(ApiClient? api, WalletService wallet) {
  // AdMob adaptörü service_locator içinde bağlanır
  if (AppConfig.isRemote && api != null) {
    // Geçici: gerçek gösterim yoksa demo fallback
    return RemoteAdService(
      api,
      () async => true,
      () async => true,
    );
  }
  return DemoAdService(wallet);
}
