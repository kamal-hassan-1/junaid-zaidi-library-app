import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/theme.dart';
import 'app_button.dart';
import 'app_text.dart';
import 'heading.dart';

/// What the student picked in [AuthRequiredDialog].
enum AuthPromptAction { signIn, createAccount, later }

/// Shown when a guest taps something that needs a real account — the OPAC
/// card today, and the other gated Home shortcuts (Student Forms, the HEC
/// libraries) as they get wired up.
///
/// The dialog only reports the choice back to its caller; it deliberately
/// knows nothing about AuthScope or route names, so it stays reusable from
/// any screen.
class AuthRequiredDialog extends StatelessWidget {
  const AuthRequiredDialog({super.key});

  /// Returns the chosen action, or null if the dialog was dismissed by
  /// tapping outside it (treated the same as "Maybe Later").
  static Future<AuthPromptAction?> show(BuildContext context) {
    return showDialog<AuthPromptAction>(
      context: context,
      builder: (_) => const AuthRequiredDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Dialog(
      backgroundColor: colors.background.primary,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Same 64px icon chip the auth screens open with, so this
            // reads as part of that flow rather than a system alert.
            Center(
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.intents.info.light.bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.lock, size: 28, color: colors.brand),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Heading(
              level: 5,
              text: 'Sign in Required',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const AppText(
              'You need to sign in or create an account to access the library '
              'catalog and your library services.',
              variant: 'bodyBase',
              tone: 'secondary',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Sign In',
              onPressed: () =>
                  Navigator.of(context).pop(AuthPromptAction.signIn),
            ),
            const SizedBox(height: AppSpacing.ms),
            AppButton(
              label: 'Create Account',
              variant: 'secondary',
              onPressed: () =>
                  Navigator.of(context).pop(AuthPromptAction.createAccount),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Maybe Later',
              variant: 'text',
              onPressed: () => Navigator.of(context).pop(AuthPromptAction.later),
            ),
          ],
        ),
      ),
    );
  }
}
