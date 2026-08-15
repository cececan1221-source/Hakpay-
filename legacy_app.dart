import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/billing_service.dart';
import '../services/service_locator.dart';
import '../services/wallet_service.dart';
import '../services/withdrawal_service.dart';
import '../repositories/catalog_repository.dart';

class AppState extends ChangeNotifier {
  UserSession? session;
  WalletBalance balance = const WalletBalance(points: 0);
  List<TaskItem> tasks = [];
  List<ShopProduct> shop = [];
  List<TransactionRecord> transactions = [];
  List<WithdrawalRequest> withdrawals = [];
  VipStatus vip = const VipStatus();
  bool loading = false;
  bool earlyAccessClaimed = false;

  final _sl = ServiceLocator.I;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    final s = await _sl.auth.currentSession();
    session = s.valueOrNull;
    if (session != null) await refreshAll();
    loading = false;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    final b = await _sl.wallet.getBalance();
    if (b.isOk) balance = b.valueOrNull!;
    final t = await _sl.catalog.getTasks();
    if (t.isOk) tasks = t.valueOrNull!;
    final sh = await _sl.catalog.getShop();
    if (sh.isOk) shop = sh.valueOrNull!;
    final tx = await _sl.wallet.getTransactions();
    if (tx.isOk) transactions = tx.valueOrNull!;
    final w = await _sl.withdrawals.list();
    if (w.isOk) withdrawals = w.valueOrNull!;
    final v = await _sl.billing.getVipStatus();
    if (v.isOk) vip = v.valueOrNull!;
    notifyListeners();
  }

  Future<String?> login(String email, String pass) async {
    final r = await _sl.auth.login(email, pass);
    return r.when(
      ok: (s) async {
        session = s;
        await refreshAll();
        notifyListeners();
        return null;
      },
      err: (m) => m,
    );
  }

  Future<void> logout() async {
    await _sl.auth.logout();
    session = null;
    balance = const WalletBalance(points: 0);
    earlyAccessClaimed = false;
    notifyListeners();
  }

  Future<String?> watchTripleAds() async {
    final r = await _sl.ads.runTripleAdCycle();
    if (r.isErr) return r.errorOrNull;
    await refreshAll();
    return null;
  }

  Future<String?> completeTask(String taskId) async {
    final r = await _sl.catalog.completeTask(taskId);
    if (r.isErr) return r.errorOrNull;
    final credit = await _sl.wallet.creditByReference(
      referenceId: 'task_$taskId${DateTime.now().millisecondsSinceEpoch}',
      reason: 'task',
    );
    if (credit.isErr) return credit.errorOrNull;
    await refreshAll();
    return null;
  }

  Future<String?> redeemShopProduct(ShopProduct product) async {
    if (product.pricePoints <= 0) {
      return 'Geçersiz ürün fiyatı';
    }
    if (balance.available < product.pricePoints) {
      return 'Yetersiz puan (${product.pricePoints} gerekli)';
    }
    if (product.requiresTripleAd) {
      final adErr = await watchTripleAds();
      if (adErr != null) return 'Üçlü reklam gerekli: $adErr';
      // Reklam sonrası bakiye değişmiş olabilir — tekrar kontrol
      await refreshAll();
      if (balance.available < product.pricePoints) {
        return 'Reklam sonrası bakiye yetersiz (${product.pricePoints} gerekli)';
      }
    }
    if (_sl.wallet is DemoWalletService) {
      final demo = _sl.wallet as DemoWalletService;
      final hold = await demo.hold(product.pricePoints);
      if (hold.isErr) return hold.errorOrNull;
      final fin = await demo.finalizeWithdrawal(product.pricePoints);
      if (fin.isErr) {
        await demo.releaseHold(product.pricePoints);
        return fin.errorOrNull;
      }
    }
    await refreshAll();
    return null;
  }

  Future<String?> claimEarlyAccess() async {
    if (earlyAccessClaimed) return 'Erken erişim bonusu zaten alındı';
    final credit = await _sl.wallet.creditByReference(
      referenceId: 'early_access_${session?.userId ?? 'x'}',
      reason: 'early_access',
    );
    if (credit.isErr) return credit.errorOrNull;
    earlyAccessClaimed = true;
    await refreshAll();
    return null;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.session == null) return const LoginScreen();
    return const HomeShell();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: 'demo@hakpay.app');
  final pass = TextEditingController(text: 'demo1234');
  bool busy = false;
  String? err;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0B1A), Color(0xFF1A0A2E), Color(0xFF0B0B1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('HakPay',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB388FF),
                    )),
                const SizedBox(height: 8),
                const Text('MVP Kapalı Test · Demo',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 40),
                _field(email, 'E-posta'),
                const SizedBox(height: 12),
                _field(pass, 'Şifre', obscure: true),
                if (err != null) ...[
                  const SizedBox(height: 12),
                  Text(err!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() {
                              busy = true;
                              err = null;
                            });
                            final e = await context
                                .read<AppState>()
                                .login(email.text.trim(), pass.text);
                            if (mounted) {
                              setState(() {
                                busy = false;
                                err = e;
                              });
                            }
                          },
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Giriş Yap'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const EarnTab(),
      const TasksTab(),
      const ParadoxMangaTab(),
      const WalletTab(),
      const ProfileTab(),
    ];
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.monetization_on), label: 'Kazan'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Görevler'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Paradox'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Cüzdan'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const GlassCard({super.key, required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

class ComingSoonOverlay extends StatelessWidget {
  final Widget child;
  const ComingSoonOverlay({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0.35, child: child),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.45),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close, color: Colors.redAccent, size: 40),
                SizedBox(height: 6),
                Text(
                  'YAKINDA GELECEK',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EarnTab extends StatelessWidget {
  const EarnTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _page(
      title: 'Kazan',
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                Text('${state.balance.points} puan',
                    style: GoogleFonts.orbitron(
                        fontSize: 28, color: const Color(0xFFB388FF))),
                Text(
                  '≈ ${AppConfig.pointsToTl(state.balance.points).toStringAsFixed(2)} TL · Sikke eşdeğeri',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final err = await state.watchTripleAds();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err ??
                      'Üçlü döngü tamam · +${AppConfig.tripleAdCyclePoints} puan'),
                ));
              }
            },
            icon: const Icon(Icons.play_circle),
            label: Text('Üçlü Reklam İzle (+${AppConfig.tripleAdCyclePoints} puan)'),
          ),
          const SizedBox(height: 8),
          Text(
            '3 reklam = ${AppConfig.tripleAdCyclePoints} puan (≈ 6 kuruş)',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Erken Erişim Bonusu',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('+5.000 puan',
                          style: TextStyle(color: Color(0xFFB388FF), fontSize: 12)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: state.earlyAccessClaimed
                      ? null
                      : () async {
                          final err = await state.claimEarlyAccess();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err ?? 'Erken erişim +5000 puan'),
                            ));
                          }
                        },
                  child: Text(state.earlyAccessClaimed ? 'Alındı' : 'Al'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _page(
      title: 'Görevler',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Anket / offerwall kazancının %${(AppConfig.offerwallUserShare * 100).toInt()}\'i size yansır',
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final t = state.tasks[i];
              return GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          Text(t.description,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          Text('+${t.rewardPoints} puan',
                              style: const TextStyle(
                                  color: Color(0xFFB388FF), fontSize: 12)),
                        ],
                      ),
                    ),
                    if (!t.completed)
                      TextButton(
                        onPressed: () async {
                          final err = await state.completeTask(t.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err ?? 'Görev tamamlandı'),
                            ));
                          }
                        },
                        child: const Text('Tamamla'),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.greenAccent),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ParadoxMangaTab extends StatelessWidget {
  const ParadoxMangaTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _page(
      title: 'Paradox Manga',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dijital varlık · Nakit çekim yok\n1.000 puan = 1 Sikke',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...state.shop.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat.decimalPattern('tr').format(p.coinAmount)} sikke  ·  ${NumberFormat.decimalPattern('tr').format(p.pricePoints)} puan',
                      style: const TextStyle(color: Color(0xFFB388FF), fontSize: 13),
                    ),
                    if (p.requiresTripleAd)
                      const Text(
                        'Satın almadan önce 3\'lü reklam izlenir',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final err = await state.redeemShopProduct(p);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(err ??
                                  '${p.coinAmount} Paradox Manga sikkesi talebi alındı'),
                            ));
                          }
                        },
                        child: const Text('Satın Al (3\'lü reklam)'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          ComingSoonOverlay(
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nakit TL Çekim',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Banka / Papara',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: null, child: const Text('Çekim')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final fmt = DateFormat('dd.MM HH:mm');
    return _page(
      title: 'Cüzdan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(
              children: [
                Text('${state.balance.points} puan',
                    style: GoogleFonts.orbitron(fontSize: 26)),
                Text('Kullanılabilir: ${state.balance.available}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ComingSoonOverlay(
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Nakit Çekim',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(enabled: false, decoration: _dec('Puan')),
                  const SizedBox(height: 8),
                  TextField(enabled: false, decoration: _dec('Papara / IBAN')),
                  const SizedBox(height: 12),
                  const FilledButton(onPressed: null, child: Text('Çekim İste')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Son İşlemler', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...state.transactions.take(8).map((tx) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${tx.description} · ${fmt.format(tx.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${tx.amount > 0 ? '+' : ''}${tx.amount}',
                        style: TextStyle(
                          color: tx.amount >= 0 ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  static InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.session;
    return _page(
      title: 'Profil',
      child: Column(
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF7C4DFF),
                  child: Text(
                    (s?.displayName.isNotEmpty == true ? s!.displayName[0] : '?')
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(s?.displayName ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(s?.email ?? '', style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 8),
                Text('VIP: ${state.vip.tier.name.toUpperCase()}',
                    style: const TextStyle(color: Color(0xFFB388FF))),
                const Text('MVP · Kapalı Test',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => state.logout(),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

Widget _page({required String title, required Widget child}) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF0B0B1A), Color(0xFF1A0A2E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(title,
              style: GoogleFonts.orbitron(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
