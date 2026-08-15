import 'package:flutter_test/flutter_test.dart';
import 'package:hakpay/config/app_config.dart';
import 'package:hakpay/services/wallet_service.dart';
import 'package:hakpay/services/ad_service.dart';

void main() {
  group('MVP Ekonomi', () {
    test('1000 puan = 1 TL = 1 sikke', () {
      expect(AppConfig.pointsPerTl, 1000);
      expect(AppConfig.pointsToTl(1000), 1.0);
    });

    test('üçlü reklam = 60 puan (3×20)', () {
      expect(AppConfig.tripleAdCyclePoints, 60);
      expect(AppConfig.singleAdPoints, 20);
      expect(AppConfig.singleAdPoints * 3, AppConfig.tripleAdCyclePoints);
    });

    test('offerwall kullanıcı payı %35', () {
      expect(AppConfig.offerwallUserShare, 0.35);
    });

    test('mağaza paketleri 80k ve 150k', () {
      expect(AppConfig.shopPack80kPoints, 80000);
      expect(AppConfig.shopPack150kPoints, 150000);
    });

    test('nakit çekim MVP kapalı', () {
      expect(AppConfig.cashWithdrawalEnabled, false);
    });

    test('ad_reward 20 puan verir', () async {
      final wallet = DemoWalletService();
      final before = (await wallet.getBalance()).valueOrNull!.points;
      final r = await wallet.creditByReference(
        referenceId: 'ad_test_1',
        reason: 'ad_reward',
      );
      expect(r.isOk, true);
      final after = (await wallet.getBalance()).valueOrNull!.points;
      expect(after - before, 20);
    });

    test('üçlü döngü toplam 60', () async {
      final wallet = DemoWalletService();
      final ads = DemoAdService(wallet);
      final before = (await wallet.getBalance()).valueOrNull!.points;
      final r = await ads.runTripleAdCycle();
      expect(r.isOk, true);
      expect(r.valueOrNull, 60);
      final after = (await wallet.getBalance()).valueOrNull!.points;
      expect(after - before, 60);
    });

    test('çift ödül engeli', () async {
      final wallet = DemoWalletService();
      final r1 = await wallet.creditByReference(
        referenceId: 'dup',
        reason: 'ad_reward',
      );
      expect(r1.isOk, true);
      final r2 = await wallet.creditByReference(
        referenceId: 'dup',
        reason: 'ad_reward',
      );
      expect(r2.isErr, true);
    });

    test('erken erişim 5000', () async {
      final wallet = DemoWalletService();
      final before = (await wallet.getBalance()).valueOrNull!.points;
      await wallet.creditByReference(
        referenceId: 'ea1',
        reason: 'early_access',
      );
      final after = (await wallet.getBalance()).valueOrNull!.points;
      expect(after - before, 5000);
    });
  });
}
