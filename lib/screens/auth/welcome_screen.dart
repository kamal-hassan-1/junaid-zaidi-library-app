import 'package:flutter/material.dart';

import '../../data/library_images.dart';
import '../../navigation/routes.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback onContinueAsGuest;

  const WelcomeScreen({super.key, required this.onContinueAsGuest});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          portraitLibraryImagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.48),
                Colors.black.withValues(alpha: 0.68),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppGrid.margin,
                AppSpacing.xxl,
                AppGrid.margin,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          offset: Offset(0, 8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Image(
                      image: AssetImage(logoImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText(
                    'Junaid Zaidi Library',
                    variant: 'h4',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppGrid.margin,
              AppSpacing.md,
              AppGrid.margin,
              AppSpacing.sm,
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
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Log in with Email',
                    variant: 'primary',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AuthRoutes.emailLogin),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Create Account',
                    variant: 'secondary',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AuthRoutes.roleSelection),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Continue as Guest',
                    variant: 'text',
                    onPressed: onContinueAsGuest,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    'For any difficulty, contact Junaid Zaidi Library.',
                    variant: 'bodySmall',
                    tone: 'tertiary',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
