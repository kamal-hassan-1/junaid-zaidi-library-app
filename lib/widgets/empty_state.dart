import 'package:flutter/widgets.dart';
import 'package:ionicons/ionicons.dart';

import '../theme/theme.dart';
import 'app_text.dart';
import 'heading.dart';

/// Shared "nothing here yet" state — used by screens that are
/// intentionally blank at this stage, so the empty treatment stays
/// consistent instead of being redrawn per screen.
///
/// Icon container background: Tertiary Background = "Interactive
/// surfaces" — slightly more visible than Secondary Background so the
/// chip reads above the screen surface.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;

  const EmptyState({
    super.key,
    this.icon = Ionicons.construct_outline,
    required this.title,
    this.description,
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
              color: colors.background.tertiary,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: colors.icon),
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
        ],
      ),
    );
  }
}
