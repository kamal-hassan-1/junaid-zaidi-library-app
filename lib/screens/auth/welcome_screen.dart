import 'package:flutter/material.dart';

import '../../navigation/routes.dart';
import '../../theme/theme.dart';
import '../../theme/tokens/colors.dart';
import '../../widgets/ui.dart';

/// First screen a signed-out student sees. Redesigned with a brand
/// gradient hero (top) overlapped by a rounded white sheet (bottom)
/// holding the Log In / Create Account choice — deliberately doesn't wrap
/// in its own Scaffold since AuthGate's nested Navigator already provides
/// one per route.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);
    final heroHeight = MediaQuery.of(context).size.height * 0.55;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: heroHeight,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppPalette.base[800]!, AppPalette.base[600]!],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -40,
                  right: -30,
                  child: _softCircle(120, AppPalette.base[500]!.withValues(alpha: 0.35)),
                ),
                Positioned(
                  bottom: 60,
                  left: -50,
                  child: _softCircle(160, AppPalette.base[400]!.withValues(alpha: 0.25)),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  offset: Offset(0, 8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: AppText(
                              'JZ',
                              variant: 'h3',
                              style: TextStyle(
                                color: AppPalette.base[700],
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppText(
                            'Junaid Zaidi Library',
                            variant: 'h3',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            'COMSATS University Islamabad',
                            variant: 'bodyBase',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: colors.background.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              boxShadow: shadow.boxShadow,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    'Get started',
                    variant: 'h5',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    'Log in with an approved account, or register for one.',
                    variant: 'bodyBase',
                    tone: 'secondary',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Log In',
                    variant: 'primary',
                    onPressed: () => Navigator.of(context).pushNamed(AuthRoutes.login),
                  ),
                  const SizedBox(height: AppSpacing.ms),
                  AppButton(
                    label: 'Create Account',
                    variant: 'secondary',
                    onPressed: () => Navigator.of(context).pushNamed(AuthRoutes.signupEmail),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _softCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}