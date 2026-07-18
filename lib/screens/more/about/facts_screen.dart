import 'package:flutter/widgets.dart';
import 'package:ionicons/ionicons.dart';

import '../../../data/about_content.dart';
import '../../../theme/theme.dart';
import '../../../widgets/ui.dart';

/// Facts about Junaid Zaidi Library (mirrors
/// `app/(tabs)/more/about/facts.js`): a simple bulleted list, each row led
/// by a small sparkle icon.
class FactsScreen extends StatelessWidget {
  const FactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final fact in libraryFacts)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Ionicons.sparkles_outline,
                      size: 18,
                      color: colors.brand,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(fact, variant: 'bodyBase', tone: 'primary'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
