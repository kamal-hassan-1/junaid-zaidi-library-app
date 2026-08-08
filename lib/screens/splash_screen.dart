import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../data/library_images.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Branded Flutter splash shown after the native OS launch plate
/// (background color only — no native icon).
///
/// Removes [FlutterNativeSplash] as soon as this widget mounts so the app
/// never sits on a blank native plate.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const double _logoSize = 120;

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom + AppSpacing.xl;

    return Scaffold(
      backgroundColor: colors.background.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppGrid.margin),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image(
                image: const AssetImage(logoImagePath),
                width: _logoSize,
                height: _logoSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              Heading(
                text: 'Junaid Zaidi Library',
                level: 4,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.text.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'COMSATS University Islamabad',
                variant: 'bodyBase',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.text.secondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppText(
                'Knowledge • Research • Innovation',
                variant: 'bodyBase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.text.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: colors.brand,
                ),
              ),
              SizedBox(height: bottomPad),
            ],
          ),
        ),
      ),
    );
  }
}
