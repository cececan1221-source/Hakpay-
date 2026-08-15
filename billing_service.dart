import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../config/app_config.dart';
import '../core/result.dart';
import 'api_client.dart';

enum VipTier { none, bronze, gold, diamond }

class VipStatus {
  final VipTier tier;
  final DateTime? expiresAt;
  final bool hasSubscription;

  const VipStatus({
    this.tier = VipTier.none,
    this.expiresAt,
    this.hasSubscription = false,
  });
}

/// Play Billing adaptörü.
/// Ürün ID'leri Play Console'da tanımlandıktan sonra AppConfig üzerinden gelir.
/// Satın alma token'ı backend'de doğrulanmalıdır.
abstract class BillingService {
  Future<void> initialize();
  Future<Result<List<ProductDetails>>> loadProducts();
  Future<Result<bool>> purchase(String productId);
  Future<Result<VipStatus>> getVipStatus();
  Future<void> restore();
  Stream<List<PurchaseDetails>> get purchaseStream;
}

class DemoBillingService implements BillingService {
  VipStatus _status = const VipStatus();

  @override
  Future<void> initialize() async {}

  @override
  Future<Result<List<ProductDetails>>> loadProducts() async {
    // Demo — gerçek ProductDetails yok
    return const Ok([]);
  }

  @override
  Future<Result<bool>> purchase(String productId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (productId.contains('bronze')) {
      _status = VipStatus(
        tier: VipTier.bronze,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    } else if (productId.contains('gold')) {
      _status = VipStatus(
        tier: VipTier.gold,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    } else if (productId.contains('diamond')) {
      _status = VipStatus(
        tier: VipTier.diamond,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
    } else if (productId.contains('sub')) {
      _status = VipStatus(
        tier: VipTier.gold,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        hasSubscription: true,
      );
    }
    return const Ok(true);
  }

  @override
  Future<Result<VipStatus>> getVipStatus() async => Ok(_status);

  @override
  Future<void> restore() async {}

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => const Stream.empty();
}

class PlayBillingService implements BillingService {
  PlayBillingService(this._api);
  final ApiClient? _api;
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  static final _productIds = {
    AppConfig.vipBronzeId,
    AppConfig.vipGoldId,
    AppConfig.vipDiamondId,
    AppConfig.subscriptionMonthlyId,
  };

  @override
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    _sub = _iap.purchaseStream.listen((purchases) async {
      _controller.add(purchases);
      for (final p in purchases) {
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          await _verifyOnBackend(p);
          if (p.pendingCompletePurchase) {
            await _iap.completePurchase(p);
          }
        }
      }
    });
  }

  Future<void> _verifyOnBackend(PurchaseDetails p) async {
    if (_api == null || AppConfig.isDemo) return;
    await _api!.post('/v1/billing/verify', body: {
      'product_id': p.productID,
      'purchase_token': p.verificationData.serverVerificationData,
      'source': p.verificationData.source,
    });
  }

  @override
  Future<Result<List<ProductDetails>>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return const Err('Mağaza kullanılamıyor');
    final res = await _iap.queryProductDetails(_productIds);
    if (res.error != null) return Err(res.error!.message);
    return Ok(res.productDetails);
  }

  @override
  Future<Result<bool>> purchase(String productId) async {
    final products = await loadProducts();
    if (products.isErr) return Err(products.errorOrNull!);
    final list = products.valueOrNull ?? [];
    final match = list.where((e) => e.id == productId);
    if (match.isEmpty) return const Err('Ürün bulunamadı');
    final param = PurchaseParam(productDetails: match.first);
    final ok = await _iap.buyNonConsumable(purchaseParam: param);
    return Ok(ok);
  }

  @override
  Future<Result<VipStatus>> getVipStatus() async {
    if (_api != null && AppConfig.isRemote) {
      final res = await _api!.get('/v1/vip/status');
      return res.when(
        ok: (d) {
          final tierStr = d['tier']?.toString() ?? 'none';
          final tier = VipTier.values.firstWhere(
            (e) => e.name == tierStr,
            orElse: () => VipTier.none,
          );
          return Ok(VipStatus(
            tier: tier,
            expiresAt: DateTime.tryParse(d['expires_at']?.toString() ?? ''),
            hasSubscription: d['has_subscription'] == true,
          ));
        },
        err: (m) => Err(m),
      );
    }
    return const Ok(VipStatus());
  }

  @override
  Future<void> restore() async {
    await _iap.restorePurchases();
  }

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

BillingService createBillingService(ApiClient? api) {
  if (AppConfig.isRemote) {
    return PlayBillingService(api);
  }
  return DemoBillingService();
}
