import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../data/library_images.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Branded splash shown while AuthGate restores the session.
///
/// The OS native splash (Android 12+ especially) can only show a centered
/// crest — it cannot render this card + title layout. This screen takes over
/// on the first Flutter frame ([FlutterNativeSplash.remove]) so the full
/// design appears as soon as Flutter is ready.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const double _logoTile = 132;

  @override
  void initState() {
    super.initState();
    // Drop the native crest-only splash the moment this branded layout paints.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);
    // Surface behind the transparent crest — secondary in dark mode so we
    // never flash a white plate on a dark background.
    final tileColor =
        colors.isDark ? colors.background.secondary : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: colors.background.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppGrid.margin),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: _logoTile,
                height: _logoTile,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: shadow.border,
                  boxShadow: shadow.boxShadow,
                ),
                child: const Image(
                  image: AssetImage(logoImagePath),
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Heading(
                text: 'Junaid Zaidi Library',
                level: 4,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.text.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                'COMSATS University Islamabad',
                variant: 'bodyBase',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.text.secondary),
              ),
              const Spacer(),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.brand,
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
