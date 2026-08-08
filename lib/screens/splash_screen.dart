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
  static const double _logoSize = 140;

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
    final bottomPad = MediaQuery.paddingOf(context).bottom + AppSpacing.md;

    return Scaffold(
      backgroundColor: colors.background.primary,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppGrid.margin,
                    0,
                    AppGrid.margin,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                    ],
                  ),
                ),
              ),
            ),
          ),
          Image(
            image: const AssetImage(logoImagePath),
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppGrid.margin,
                AppSpacing.lg,
                AppGrid.margin,
                bottomPad,
              ),
              child: Column(
                children: [
                  AppText(
                    'Knowledge • Research • Innovation',
                    variant: 'bodyBase',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.text.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colors.brand,
                    ),
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
