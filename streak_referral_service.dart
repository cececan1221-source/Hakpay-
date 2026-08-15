import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../core/result.dart';
import 'api_client.dart';
import 'wallet_service.dart';

class StreakInfo {
  final int currentDays;
  final int longestDays;
  final bool claimedToday;
  final int todayReward;

  const StreakInfo({
    this.currentDays = 0,
    this.longestDays = 0,
    this.claimedToday = false,
    this.todayReward = 25,
  });
}

class ReferralInfo {
  final String code;
  final int invitedCount;
  final int earnedPoints;

  const ReferralInfo({
    required this.code,
    this.invitedCount = 0,
    this.earnedPoints = 0,
  });
}

abstract class StreakService {
  Future<Result<StreakInfo>> getStreak();
  Future<Result<int>> claimDaily();
}

abstract class ReferralService {
  Future<Result<ReferralInfo>> getInfo();
  Future<Result<int>> applyCode(String code);
}

class DemoStreakService implements StreakService {
  int _days = 3;
  bool _claimed = false;
  final WalletService _wallet;
  final _uuid = const Uuid();

  DemoStreakService(this._wallet);

  @override
  Future<Result<StreakInfo>> getStreak() async => Ok(StreakInfo(
        currentDays: _days,
        longestDays: _days + 2,
        claimedToday: _claimed,
        todayReward: 25 + (_days * 5),
      ));

  @override
  Future<Result<int>> claimDaily() async {
    if (_claimed) return const Err('Bugünkü streak zaten alındı');
    _claimed = true;
    _days += 1;
    final reward = 25 + (_days * 5);
    final ref = 'streak_${_uuid.v4()}';
    final credit = await _wallet.creditByReference(
      referenceId: ref,
      reason: 'task',
    );
    return credit.when(ok: (_) => Ok(reward), err: (m) => Err(m));
  }
}

class DemoReferralService implements ReferralService {
  final WalletService _wallet;
  final _uuid = const Uuid();
  String _code = 'HAKPAY${DateTime.now().millisecondsSinceEpoch % 10000}';

  DemoReferralService(this._wallet);

  @override
  Future<Result<ReferralInfo>> getInfo() async => Ok(ReferralInfo(
        code: _code,
        invitedCount: 2,
        earnedPoints: 1000,
      ));

  @override
  Future<Result<int>> applyCode(String code) async {
    if (code.trim().isEmpty) return const Err('Kod boş');
    if (code == _code) return const Err('Kendi kodunu kullanamazsın');
    final ref = 'referral_${_uuid.v4()}';
    final credit = await _wallet.creditByReference(
      referenceId: ref,
      reason: 'referral',
    );
    return credit.when(ok: (_) => const Ok(500), err: (m) => Err(m));
  }
}

class RemoteStreakService implements StreakService {
  RemoteStreakService(this._api);
  final ApiClient _api;

  @override
  Future<Result<StreakInfo>> getStreak() async {
    final res = await _api.get('/v1/streak');
    return res.when(
      ok: (d) => Ok(StreakInfo(
        currentDays: (d['current_days'] as num?)?.toInt() ?? 0,
        longestDays: (d['longest_days'] as num?)?.toInt() ?? 0,
        claimedToday: d['claimed_today'] == true,
        todayReward: (d['today_reward'] as num?)?.toInt() ?? 25,
      )),
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<int>> claimDaily() async {
    final res = await _api.post('/v1/streak/claim');
    return res.when(
      ok: (d) => Ok((d['points'] as num?)?.toInt() ?? 0),
      err: (m) => Err(m),
    );
  }
}

class RemoteReferralService implements ReferralService {
  RemoteReferralService(this._api);
  final ApiClient _api;

  @override
  Future<Result<ReferralInfo>> getInfo() async {
    final res = await _api.get('/v1/referral');
    return res.when(
      ok: (d) => Ok(ReferralInfo(
        code: d['code']?.toString() ?? '',
        invitedCount: (d['invited_count'] as num?)?.toInt() ?? 0,
        earnedPoints: (d['earned_points'] as num?)?.toInt() ?? 0,
      )),
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<int>> applyCode(String code) async {
    final res = await _api.post('/v1/referral/apply', body: {'code': code});
    return res.when(
      ok: (d) => Ok((d['points'] as num?)?.toInt() ?? 0),
      err: (m) => Err(m),
    );
  }
}

StreakService createStreakService(ApiClient? api, WalletService wallet) {
  if (AppConfig.isRemote && api != null) return RemoteStreakService(api);
  return DemoStreakService(wallet);
}

ReferralService createReferralService(ApiClient? api, WalletService wallet) {
  if (AppConfig.isRemote && api != null) return RemoteReferralService(api);
  return DemoReferralService(wallet);
}
