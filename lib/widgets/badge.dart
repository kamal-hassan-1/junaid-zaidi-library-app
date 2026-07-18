import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'app_text.dart';

/// Shelf / Category Badge. Small pill label, e.g. "Coming soon",
/// "Currently Reading".
class AppBadge extends StatelessWidget {
  final String label;
  final String intent;

  const AppBadge({super.key, required this.label, this.intent = 'neutral'});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    final Color bg;
    final Color fg;
    switch (intent) {
      case 'info':
        bg = colors.intents.info.light.bg;
        fg = colors.intents.info.light.fg;
        break;
      case 'success':
        bg = colors.intents.success.light.bg;
        fg = colors.intents.success.light.fg;
        break;
      case 'warning':
        bg = colors.intents.warning.light.bg;
        fg = colors.intents.warning.light.fg;
        break;
      case 'error':
        bg = colors.intents.error.light.bg;
        fg = colors.intents.error.light.fg;
        break;
      case 'neutral':
      default:
        bg = colors.background.tertiary;
        fg = colors.text.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: AppText(label, variant: 'caption', style: TextStyle(color: fg)),
    );
  }
}
