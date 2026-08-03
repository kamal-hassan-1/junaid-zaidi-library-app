import 'package:flutter/material.dart';

import '../data/library_images.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Branded launch screen, shown while AuthGate restores the Koha/Firebase
/// session on boot.
///
/// Deliberately continues the native launch screen's composition (the COMSATS
/// crest on a light background — see the `flutter_native_splash` block in
/// pubspec.yaml) so the handoff from the OS splash to the first Flutter frame
/// reads as one screen rather than two. Everything below the crest fades up
/// afterwards, which is what visually distinguishes this from the static
/// native one.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Minimum time the splash stays up. Session restore is usually faster than
  /// this, and a splash that vanishes in 80ms reads as a flicker/glitch.
  static const minimumDuration = Duration(milliseconds: 1400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 900),
    vsync: this,
  )..forward();

  late final Animation<double> _crestScale = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
  );

  late final Animation<double> _textFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    // Scaffold, not a bare Container: AuthGate hands this straight to
    // MaterialApp.home, so without a Material ancestor every AppText inherits
    // the framework's "missing DefaultTextStyle" fallback and renders with
    // yellow double underlines.
    return Scaffold(
      backgroundColor: colors.background.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppGrid.margin),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: Tween(begin: 0.82, end: 1.0).animate(_crestScale),
                child: Container(
                  width: 132,
                  height: 132,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: shadow.border,
                    boxShadow: shadow.boxShadow,
                  ),
                  child: Image.asset(logoImagePath, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeTransition(
                opacity: _textFade,
                child: Column(
                  children: [
                    const Heading(
                      text: 'Junaid Zaidi Library',
                      level: 4,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const AppText(
                      'COMSATS University Islamabad',
                      variant: 'bodyBase',
                      tone: 'secondary',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _textFade,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.brand,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
