import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../core/result.dart';
import 'api_client.dart';
import 'wallet_service.dart';

enum WithdrawalStatus {
  pending, // hold alındı, admin onayı bekliyor
  approved,
  rejected,
  paid,
  cancelled,
}

class WithdrawalRequest {
  final String id;
  final int points;
  final double tl;
  final String method; // papara | bank | other
  final String destination; // iban / papara no
  final WithdrawalStatus status;
  final DateTime createdAt;
  final String? note;

  const WithdrawalRequest({
    required this.id,
    required this.points,
    required this.tl,
    required this.method,
    required this.destination,
    required this.status,
    required this.createdAt,
    this.note,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> j) {
    final statusStr = j['status']?.toString() ?? 'pending';
    final status = WithdrawalStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => WithdrawalStatus.pending,
    );
    return WithdrawalRequest(
      id: j['id']?.toString() ?? '',
      points: (j['points'] as num?)?.toInt() ?? 0,
      tl: (j['tl'] as num?)?.toDouble() ?? 0,
      method: j['method']?.toString() ?? '',
      destination: j['destination']?.toString() ?? '',
      status: status,
      createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      note: j['note']?.toString(),
    );
  }
}

/// Çekim: önce hold, sonra admin onay.
abstract class WithdrawalService {
  Future<Result<WithdrawalRequest>> request({
    required int points,
    required String method,
    required String destination,
  });
  Future<Result<List<WithdrawalRequest>>> list();
  Future<Result<WithdrawalRequest>> cancel(String id);
}

class DemoWithdrawalService implements WithdrawalService {
  final DemoWalletService _wallet;
  final _list = <WithdrawalRequest>[];
  final _uuid = const Uuid();

  DemoWithdrawalService(this._wallet);

  @override
  Future<Result<WithdrawalRequest>> request({
    required int points,
    required String method,
    required String destination,
  }) async {
    if (!AppConfig.cashWithdrawalEnabled) {
      return const Err('Nakit çekim şu an kapalı (Yakında gelecek)');
    }
    if (points < AppConfig.pointsPerTl) {
      return const Err('Minimum çekim 1 TL (1000 puan)');
    }
    if (destination.trim().isEmpty) {
      return const Err('Hedef hesap boş olamaz');
    }
    final hold = await _wallet.hold(points);
    if (hold.isErr) return Err(hold.errorOrNull!);

    final req = WithdrawalRequest(
      id: _uuid.v4(),
      points: points,
      tl: AppConfig.pointsToTl(points),
      method: method,
      destination: destination,
      status: WithdrawalStatus.pending,
      createdAt: DateTime.now(),
      note: 'Demo — admin onayı simüle edilmedi',
    );
    _list.insert(0, req);
    return Ok(req);
  }

  @override
  Future<Result<List<WithdrawalRequest>>> list() async => Ok(List.of(_list));

  @override
  Future<Result<WithdrawalRequest>> cancel(String id) async {
    final idx = _list.indexWhere((e) => e.id == id);
    if (idx < 0) return const Err('Talep bulunamadı');
    final old = _list[idx];
    if (old.status != WithdrawalStatus.pending) {
      return const Err('Sadece bekleyen talepler iptal edilebilir');
    }
    await _wallet.releaseHold(old.points);
    final updated = WithdrawalRequest(
      id: old.id,
      points: old.points,
      tl: old.tl,
      method: old.method,
      destination: old.destination,
      status: WithdrawalStatus.cancelled,
      createdAt: old.createdAt,
      note: 'İptal edildi',
    );
    _list[idx] = updated;
    return Ok(updated);
  }
}

class RemoteWithdrawalService implements WithdrawalService {
  RemoteWithdrawalService(this._api);
  final ApiClient _api;

  @override
  Future<Result<WithdrawalRequest>> request({
    required int points,
    required String method,
    required String destination,
  }) async {
    if (!AppConfig.cashWithdrawalEnabled) {
      return const Err('Nakit çekim şu an kapalı (Yakında gelecek)');
    }
    if (destination.trim().isEmpty) {
      return const Err('Hedef hesap boş olamaz');
    }
    final res = await _api.post('/v1/withdrawals', body: {
      'points': points,
      'method': method,
      'destination': destination.trim(),
    });
    return res.when(
      ok: (d) => Ok(WithdrawalRequest.fromJson(d)),
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<List<WithdrawalRequest>>> list() async {
    final res = await _api.get('/v1/withdrawals');
    return res.when(
      ok: (d) {
        final list = (d['items'] as List?) ?? [];
        return Ok(list
            .whereType<Map<String, dynamic>>()
            .map(WithdrawalRequest.fromJson)
            .toList());
      },
      err: (m) => Err(m),
    );
  }

  @override
  Future<Result<WithdrawalRequest>> cancel(String id) async {
    final res = await _api.post('/v1/withdrawals/$id/cancel');
    return res.when(
      ok: (d) => Ok(WithdrawalRequest.fromJson(d)),
      err: (m) => Err(m),
    );
  }
}

WithdrawalService createWithdrawalService(
  ApiClient? api,
  WalletService wallet,
) {
  if (AppConfig.isRemote && api != null) {
    return RemoteWithdrawalService(api);
  }
  if (wallet is DemoWalletService) {
    return DemoWithdrawalService(wallet);
  }
  return DemoWithdrawalService(DemoWalletService());
}
