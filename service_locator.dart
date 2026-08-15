import '../config/app_config.dart';
import '../repositories/catalog_repository.dart';
import 'ad_service.dart';
import 'admob_ad_service.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'billing_service.dart';
import 'notification_service.dart';
import 'streak_referral_service.dart';
import 'wallet_service.dart';
import 'withdrawal_service.dart';

/// Tek giriş noktası — demo / remote otomatik seçilir.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator I = ServiceLocator._();

  late final ApiClient? api;
  late final AuthService auth;
  late final WalletService wallet;
  late final WithdrawalService withdrawals;
  late final AdService ads;
  late final BillingService billing;
  late final CatalogRepository catalog;
  late final StreakService streak;
  late final ReferralService referral;
  late final NotificationService notifications;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;

    api = AppConfig.isRemote ? ApiClient() : null;

    auth = createAuthService(api);
    wallet = createWalletService(api);
    withdrawals = createWithdrawalService(api, wallet);
    ads = createAdMobAwareAdService(api, wallet);
    billing = createBillingService(api);
    catalog = createCatalogRepository(api);
    streak = createStreakService(api, wallet);
    referral = createReferralService(api, wallet);
    notifications = createNotificationService();

    await billing.initialize();
    await notifications.initialize();

    // AdMob ön yükleme (hata olursa sessiz geç)
    if (ads is AdMobAdService) {
      try {
        await (ads as AdMobAdService).initialize();
      } catch (_) {}
    }

    _ready = true;
  }

  bool get isDemo => AppConfig.isDemo;
}
