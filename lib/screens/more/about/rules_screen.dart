import 'package:flutter/widgets.dart';

import '../../../data/about_content.dart';
import '../../../theme/theme.dart';
import '../../../widgets/ui.dart';

/// Rules and Regulations (mirrors `app/(tabs)/more/about/rules.js`): a
/// numbered list, each row led by a small numbered circle instead of an
/// icon.
class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in libraryRules.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.background.tertiary,
                    ),
                    alignment: Alignment.center,
                    child: AppText(
                      '${entry.key + 1}',
                      variant: 'bodySmall',
                      tone: 'secondary',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(entry.value, variant: 'bodyBase', tone: 'primary'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
