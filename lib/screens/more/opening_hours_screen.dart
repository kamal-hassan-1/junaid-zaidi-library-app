import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../data/library_images.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Library opening hours — also linked from Home and More.
class OpeningHoursScreen extends StatelessWidget {
  const OpeningHoursScreen({super.key});

  static const _schedule = <(String, String)>[
    ('Monday – Thursday', '8:00 AM – 9:00 PM'),
    ('Friday', '8:00 AM – 5:00 PM'),
    ('Saturday & Sunday', 'Closed'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                frontDeskImagePath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Heading(level: 4, text: 'Opening Hours'),
          const SizedBox(height: AppSpacing.lg),
          Container(
            decoration: BoxDecoration(
              color: colors.background.secondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: shadow.border,
              boxShadow: shadow.boxShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < _schedule.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.ms,
                    ),
                    decoration: BoxDecoration(
                      border: i < _schedule.length - 1
                          ? Border(bottom: BorderSide(color: colors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 18,
                          color: colors.brand,
                        ),
                        const SizedBox(width: AppSpacing.ms),
                        Expanded(
                          child: AppText(
                            _schedule[i].$1,
                            variant: 'bodyBase',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        AppText(
                          _schedule[i].$2,
                          variant: 'bodySmall',
                          tone: 'secondary',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppText(
            'On Fridays, service counters close from 1:00 PM to 2:00 PM for Jumma prayer.',
            variant: 'bodyBase',
            tone: 'secondary',
          ),
        ],
      ),
    );
  }
}
