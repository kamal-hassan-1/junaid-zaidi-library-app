import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/theme.dart';
import 'app_button.dart';
import 'app_text.dart';
import 'heading.dart';

/// "Something went wrong" counterpart to [EmptyState], with the same
/// anatomy — icon chip, heading, description — so the two read as
/// siblings rather than as two different designers' work. The icon chip
/// is tinted with the error color instead of Tertiary Background, which
/// is the only visual difference, plus an optional retry action.
class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorState({
    super.key,
    this.icon = LucideIcons.triangle_alert,
    this.title = 'Something went wrong',
    this.description,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: withOpacity(colors.error, 0.12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: colors.error),
          ),
          const SizedBox(height: AppSpacing.md),
          Heading(level: 4, text: title, textAlign: TextAlign.center),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AppText(
                description!,
                variant: 'bodyBase',
                tone: 'secondary',
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: retryLabel,
              variant: 'secondary',
              fullWidth: false,
              icon: LucideIcons.refresh_cw,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
