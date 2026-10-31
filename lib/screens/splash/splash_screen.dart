import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart';
import '../../providers/product_provider.dart';

/// Splash "Angker.id": huruf berjatuhan satu per satu, memantul saat mendarat,
/// lalu bayangan & tagline muncul. Semua digerakkan oleh SATU AnimationController
/// supaya sinkron dan stabil 60 fps.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _letters = [
    'A',
    'n',
    'g',
    'k',
    'e',
    'r',
    '.',
    'i',
    'd'
  ];
  static const List<Color> _cycle = [
    AppColors.pinkDeep,
    AppColors.blueDeep,
    AppColors.mintDeep
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  late final List<Animation<double>> _fall;
  late final List<Animation<double>> _spin;
  late final List<Animation<double>> _fade;
  late final Animation<double> _shadow;
  late final Animation<double> _tagline;
  late final Animation<double> _ghost;

  bool _ready = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Huruf ke-i mulai di i*0.055 dan mendarat 0.36 kemudian (huruf terakhir ±0.80).
    _fall = [];
    _spin = [];
    _fade = [];
    for (var i = 0; i < _letters.length; i++) {
      final start = i * 0.055;
      final end = (start + 0.36).clamp(0.0, 1.0);
      _fall.add(_c.drive(
          CurveTween(curve: Interval(start, end, curve: Curves.bounceOut))));
      _spin.add(_c.drive(
          CurveTween(curve: Interval(start, end, curve: Curves.easeOutBack))));
      _fade.add(_c.drive(CurveTween(
          curve: Interval(start, start + (end - start) * 0.3,
              curve: Curves.easeOut))));
    }
    _shadow = _c.drive(CurveTween(
        curve: const Interval(0.62, 0.92, curve: Curves.easeOutCubic)));
    _tagline = _c.drive(CurveTween(
        curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic)));
    _ghost = _c.drive(
        CurveTween(curve: const Interval(0.82, 1.0, curve: Curves.elasticOut)));

    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Timer(const Duration(milliseconds: 450), _goHome);
      }
    });

    // Mulai memuat data Beranda di belakang layar agar transisi mulus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final products = context.read<ProductProvider>();
      if (!products.initialized && !products.isLoading) products.fetchInitial();
      context.read<CategoryProvider>().fetchCategoryList();
    });

    _prepareAndStart();
  }

  /// Tunggu font Google selesai dimuat (maks 1.5 dtk) supaya huruf tidak
  /// berganti font di tengah animasi.
  Future<void> _prepareAndStart() async {
    try {
      await GoogleFonts.pendingFonts([
        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        GoogleFonts.nunitoSans(fontWeight: FontWeight.w400),
      ]).timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      // Offline / timeout: tetap lanjut dengan font fallback.
    }
    if (!mounted) return;
    setState(() => _ready = true);
    _c.forward();
  }

  void _goHome() {
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color _colorFor(int i) {
    if (_letters[i] == '.') return AppColors.pink;
    return _cycle[i % _cycle.length];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final letterStyle =
        AppText.heading(52, weight: FontWeight.w800, height: 1.1);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.background, AppColors.blue],
            stops: [0, 0.5, 1],
          ),
        ),
        child: !_ready
            ? const SizedBox.expand()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hantu kecil yang "muncul" setelah semua huruf mendarat.
                  AnimatedBuilder(
                    animation: _ghost,
                    builder: (context, child) => Opacity(
                      opacity: _ghost.value.clamp(0.0, 1.0),
                      child: Transform.scale(
                          scale: 0.4 + 0.6 * _ghost.value, child: child),
                    ),
                    child: const Text('👻', style: TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(height: 8),
                  RepaintBoundary(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(_letters.length, (i) {
                        final dir = i.isEven ? 1.0 : -1.0;
                        return FadeTransition(
                          opacity: _fade[i],
                          child: AnimatedBuilder(
                            animation: _c,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                  0, (1 - _fall[i].value) * -height * 0.6),
                              child: Transform.rotate(
                                angle: (1 - _spin[i].value) * 0.35 * dir,
                                child: child,
                              ),
                            ),
                            child: Text(_letters[i],
                                style:
                                    letterStyle.copyWith(color: _colorFor(i))),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Bayangan elips yang mengembang di bawah teks.
                  AnimatedBuilder(
                    animation: _shadow,
                    builder: (context, child) => Opacity(
                      opacity: _shadow.value * 0.9,
                      child: Transform.scale(
                          scaleX: _shadow.value, scaleY: 1, child: child),
                    ),
                    child: Container(
                      width: 190,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(95, 6)),
                        gradient: RadialGradient(
                          colors: [
                            AppColors.pinkDeep.withValues(alpha: 0.28),
                            AppColors.pinkDeep.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  AnimatedBuilder(
                    animation: _tagline,
                    builder: (context, child) => Opacity(
                      opacity: _tagline.value,
                      child: Transform.translate(
                          offset: Offset(0, 12 * (1 - _tagline.value)),
                          child: child),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Belanja santai, harga bikin merinding',
                          style: AppText.body(15,
                              weight: FontWeight.w600, color: AppColors.plum),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ANGKER NOT SCARY',
                          style: AppText.label(11, color: AppColors.primary)
                              .copyWith(letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
