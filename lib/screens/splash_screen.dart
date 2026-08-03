import 'package:flutter/material.dart';

import '../data/library_images.dart';
import '../theme/theme.dart';

/// Continuation of the native Android launch screen while AuthGate restores
/// the Koha/Firebase session.
///
/// Must stay visually identical to the native splash (centered crest on
/// [SemanticColors.background.primary] / #F8F9FA) so the OS → Flutter handoff
/// reads as one screen, not two. No card, heading, or entrance animation.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Floor so a near-instant session restore does not flicker the splash off.
  /// Overlaps the real auth work in AuthGate rather than stacking after it.
  static const minimumDuration = Duration(milliseconds: 900);

  /// Logical size of the crest — matches the native pre-Android-12 splash
  /// asset (528px @xxxhdpi → 132 logical px).
  static const double logoSize = 132;

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    // Scaffold supplies Material / DefaultTextStyle (avoids yellow underlines
    // when AuthGate mounts this as MaterialApp.home with no other ancestor).
    return Scaffold(
      backgroundColor: colors.background.primary,
      body: Stack(
        children: [
          Center(
            child: Image.asset(
              logoImagePath,
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.brand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
