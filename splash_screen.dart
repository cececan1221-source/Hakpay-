import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'legacy_app.dart';

/// Premium açılış ekranı — logo animasyonu + kurumsal metinler.
/// Bitişte [AuthGate] ekranına [Navigator.pushReplacement] ile geçer.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotate;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _lineWidth;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
    _logoRotate = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.25, 0.9, curve: Curves.easeInOut),
      ),
    );
    _glowPulse = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _logoCtrl.forward();
    if (!mounted) return;
    await _textCtrl.forward();
    // Metinler okunsun
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070714),
              Color(0xFF12082A),
              Color(0xFF0B0B1A),
              Color(0xFF0A0618),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Soft ambient orbs
            Positioned(
              top: -size.height * 0.12,
              right: -size.width * 0.2,
              child: AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Container(
                  width: size.width * 0.7,
                  height: size.width * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF7C4DFF).withValues(alpha: _glowPulse.value * 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.08,
              left: -size.width * 0.25,
              child: AnimatedBuilder(
                animation: _glowPulse,
                builder: (_, __) => Container(
                  width: size.width * 0.65,
                  height: size.width * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFB388FF).withValues(alpha: _glowPulse.value * 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Logo
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, __) {
                        return Opacity(
                          opacity: _logoOpacity.value,
                          child: Transform.rotate(
                            angle: _logoRotate.value * math.pi,
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: _LogoMark(glow: _glowPulse),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Brand name
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Text(
                          'HakPay',
                          style: GoogleFonts.orbitron(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            color: const Color(0xFFE8DEFF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _logoCtrl,
                      builder: (_, __) => Opacity(
                        opacity: _logoOpacity.value * 0.75,
                        child: Text(
                          'Görev tamamla · Puan kazan',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.6,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Divider line
                    AnimatedBuilder(
                      animation: _lineWidth,
                      builder: (_, __) {
                        return Center(
                          child: Container(
                            height: 1.2,
                            width: 160 * _lineWidth.value,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFB388FF),
                                  Color(0xFF7C4DFF),
                                  Color(0xFFB388FF),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // Prestige copy
                    SlideTransition(
                      position: _textSlide,
                      child: FadeTransition(
                        opacity: _textOpacity,
                        child: Column(
                          children: [
                            Text(
                              'Geliştirici',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.2,
                                color: const Color(0xFFB388FF),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Bu uygulama, yaratıcı vizyonu ve teknik altyapısıyla '
                              'Cemalcan tarafından geliştirilmiştir.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                height: 1.55,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Yatırım & Vizyon',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.2,
                                color: const Color(0xFFB388FF),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Proje, dijital yayıncılık dünyasında çığır açan '
                              'Paradox Manga platformunun vizyoner kurucusu ve ana '
                              'yatırımcısının stratejik desteğiyle hayata geçirilmiştir. '
                              'Bu güçlü ortaklık; platformun büyüme gücünü, kararlılığını '
                              've sektöre getirdiği yenilikçi soluğu simgelemektedir.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                height: 1.6,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Bottom subtle brand
                    FadeTransition(
                      opacity: _textOpacity,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          'Paradox Manga × HakPay',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            letterSpacing: 1.4,
                            color: Colors.white24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final Animation<double> glow;
  const _LogoMark({required this.glow});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glow,
      builder: (_, __) {
        return Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: glow.value * 0.55),
                blurRadius: 36,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: const Color(0xFFB388FF).withValues(alpha: glow.value * 0.25),
                blurRadius: 60,
                spreadRadius: 8,
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFB388FF),
                Color(0xFF7C4DFF),
                Color(0xFF5E35B1),
              ],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A0A2E),
                  Color(0xFF12082A),
                ],
              ),
            ),
            child: Center(
              child: Text(
                'H',
                style: GoogleFonts.orbitron(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE8DEFF),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
