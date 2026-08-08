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
  static const double _logoSize = 108;
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
    final bottomPad = MediaQuery.paddingOf(context).bottom + AppSpacing.lg+AppSpacing.md;
    return Scaffold(
      backgroundColor: colors.background.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppGrid.margin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Heading(
                      text: 'Junaid Zaidi Library',
                      level: 4,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.text.primary,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: AppText(
                      'COMSATS University Islamabad',
                      variant: 'bodyBase',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.text.secondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: _logoSize + AppSpacing.lg,
                    height: _logoSize + AppSpacing.lg,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: colors.brand.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image(
                      image: const AssetImage(logoImagePath),
                      width: _logoSize,
                      height: _logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: AppText(
                      'Knowledge • Research • Innovation',
                      variant: 'bodySmall',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.text.tertiary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 4),
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
    );
  }
}