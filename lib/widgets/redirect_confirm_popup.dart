import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'app_button.dart';
import 'app_text.dart';
import 'card.dart';
import 'heading.dart';

/// Default copy for actions that open the Junaid Zaidi Library website.
const String kLibraryWebsiteRedirectMessage =
    'This action will redirect you to the Junaid Zaidi Library website.';

/// Default copy for other external redirects (e.g. Koha thesis catalog).
const String kExternalRedirectMessage =
    'This action will redirect you to an external website.';

/// Shows a branded confirm dialog before an action that leaves the current
/// screen (external URL, dialer, mail, etc.).
///
/// Returns `true` if the user taps Continue, `false` on Cancel / dismiss.
/// [message] is required so each call site can pass the default website
/// copy or a custom line for non-website destinations.
Future<bool> showRedirectConfirmPopup(
  BuildContext context, {
  required String message,
  String title = 'Continue?',
  String confirmLabel = 'Continue',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => RedirectConfirmPopup(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  return result ?? false;
}

/// In-app confirm popup. Prefer [showRedirectConfirmPopup] at call sites;
/// this widget exists so the dialog content stays testable and reusable.
class RedirectConfirmPopup extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;

  const RedirectConfirmPopup({
    super.key,
    required this.message,
    this.title = 'Continue?',
    this.confirmLabel = 'Continue',
    this.cancelLabel = 'Cancel',
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.background.secondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: shadow.border,
          boxShadow: shadow.boxShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Heading(level: 5, text: title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.ms),
            AppText(
              message,
              variant: 'bodyBase',
              tone: 'secondary',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: confirmLabel,
              variant: 'primary',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: cancelLabel,
              variant: 'text',
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
