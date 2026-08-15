import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../core/result.dart';
import 'api_client.dart';

class WalletBalance {
  final int points;
  final int heldPoints; // çekim hold
  const WalletBalance({required this.points, this.heldPoints = 0});

  int get available => (points - heldPoints).clamp(0, points);
  double get tl => AppConfig.pointsToTl(points);
}

class TransactionRecord {
  final String id;
  final String type; // credit | debit | hold | release | withdrawal
  final int amount;
  final String description;
  final DateTime createdAt;
  final String? referenceId;

  const TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.referenceId,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> j) =>
      TransactionRecord(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        description: j['description']?.toString() ?? '',
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
        referenceId: j['reference_id']?.toString(),
      );
}

/// Bakiye otoritesi sunucudadır.
/// credit() istemciden miktar almaz — sadece reference + type gönderir,
/// sunucu miktarı belirler / doğrular.
abstract class WalletService {
  Future<Result<WalletBalance>> getBalance();
  Future<Result<List<TransactionRecord>>> getTransactions({int limit = 50});

  /// Sunucu tarafı credit. İstemci amount göndermez.
  /// [referenceId] tek kullanımlık olmalı (çift ödül engeli).
  Future<Result<WalletBalance>> creditByReference({
    required String referenceId,
    required String reason, // ad_reward | task | survey | offerwall | referral | wheel
  });
}

class DemoWalletService implements WalletService {
  int _points = 2500;
  int _held = 0;
  final _tx = <TransactionRecord>[];
  final _usedRefs = <String>{};
  final _uuid = const Uuid();

  @override
  Future<Result<WalletBalance>> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Ok(WalletBalance(points: _points, heldPoints: _held));
  }

  @override
  Future<Result<List<TransactionRecord>>> getTransactions(
      {int limit = 50}) async {
    return Ok(_tx.take(limit).toList());
  }

  @override
  Future<Result<WalletBalance>> creditByReference({
    required String referenceId,
    required String reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final ref = referenceId.trim();
    if (ref.isEmpty) {
      return const Err('Geçersiz referans kimliği');
    }
    if (_usedRefs.contains(ref)) {
      return const Err('Bu ödül zaten kullanıldı (çift ödül engeli)');
    }
    referenceId = ref;
    // MVP ekonomi — gerçekte sunucu belirler
    // ad_reward: 20 puan (3×20 = 60 üçlü döngü)
    // survey/offerwall: brüt × %35
    final amount = switch (reason) {
      'ad_reward' => AppConfig.singleAdPoints,
      'triple_ad' => AppConfig.tripleAdCyclePoints,
      'task' => 100,
      'survey' => (200 * AppConfig.offerwallUserShare).round(),
      'offerwall' => (150 * AppConfig.offerwallUserShare).round(),
      'referral' => 500,
      'wheel' => 75,
      'early_access' => AppConfig.earlyAccessBonusPoints,
      _ => 25,
    };
    _usedRefs.add(referenceId);
    _points += amount;
    _tx.insert(
      0,
      TransactionRecord(
        id: _uuid.v4(),
        type: 'credit',
        amount: amount,
        description: reason,
        createdAt: DateTime.now(),
        referenceId: referenceId,
      ),
    );
    return Ok(WalletBalance(points: _points, heldPoints: _held));
  }

  // Demo yardımcı: hold (withdrawal servisi kullanır)
  Future<Result<WalletBalance>> hold(int amount) async {
    if (amount <= 0 || amount > (_points - _held)) {
      return const Err('Yetersiz bakiye');
    }
    _held += amount;
    return Ok(WalletBalance(points: _points, heldPoints: _held));
  }

  Future<Result<WalletBalance>> releaseHold(int amount) async {
    _held = (_held - amount).clamp(0, _points);
    return Ok(WalletBalance(points: _points, heldPoints: _held));
  }

  Future<Result<WalletBalance>> finalizeWithdrawal(int amount) async {
    if (amount > _held) return const Err('Hold yetersiz');
    _held -= amount;
    _points -= amount;
    _tx.insert(
      0,
      TransactionRecord(
        id: _uuid.v4(),
        type: 'withdrawal',
        amount: -amount,
        description: 'Çekim tamamlandı',
        createdAt: DateTime.now(),
      ),
    );
    return Ok(WalletBalance(points: _points, heldPoints: _held));
  }
}

class RemoteWalletService implements WalletService {
  RemoteWalletService(this._api);
  final ApiClient _api;

  @override
  Future<Result<WalletBalance>> getBalance() async {
    final res = await _api.get('/v1/wallet/balance');
    return res.when(
      ok: (d) => Ok(WalletBalance(
        points: (d['points'] as num?)?.toInt() ?? 0,
        heldPoints: (d['held_points'] as num?)?.toInt() ?? 0,
      )),
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<List<TransactionRecord>>> getTransactions(
      {int limit = 50}) async {
    final res = await _api.get('/v1/wallet/transactions?limit=$limit');
    return res.when(
      ok: (d) {
        final list = (d['items'] as List?) ?? (d['transactions'] as List?) ?? [];
        return Ok(list
            .whereType<Map<String, dynamic>>()
            .map(TransactionRecord.fromJson)
            .toList());
      },
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<WalletBalance>> creditByReference({
    required String referenceId,
    required String reason,
  }) async {
    if (referenceId.trim().isEmpty) {
      return const Err('Geçersiz referans kimliği');
    }
    // İstemci amount GÖNDERMEZ — sunucu belirler / doğrular
    final res = await _api.post('/v1/wallet/credit', body: {
      'reference_id': referenceId.trim(),
      'reason': reason,
    });
    return res.when(
      ok: (d) => Ok(WalletBalance(
        points: (d['points'] as num?)?.toInt() ?? 0,
        heldPoints: (d['held_points'] as num?)?.toInt() ?? 0,
      )),
      err: (m) => Err(m),
    );
  }
}

WalletService createWalletService(ApiClient? api) {
  if (AppConfig.isRemote && api != null) return RemoteWalletService(api);
  return DemoWalletService();
}
