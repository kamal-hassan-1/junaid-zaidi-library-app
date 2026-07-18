import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../data/more_menu.dart';
import '../../data/student_profile.dart';
import '../../navigation/routes.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Grouped list container — a card-like surface holding several [ListRow]s
/// stacked with dividers. (Profile and Guides screens define their own
/// private copy of this same helper rather than importing it from here.)
Widget groupedList(SemanticColors colors, List<Widget> rows) {
  final shadow = cardShadowDecoration(colors);
  return Container(
    decoration: BoxDecoration(
      color: colors.background.secondary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: shadow.border,
      boxShadow: shadow.boxShadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: rows),
  );
}

const Map<MoreMenuSection, String> _sectionLabels = {
  MoreMenuSection.library: 'Library',
  MoreMenuSection.community: 'Community',
};

Widget _buildSectionList(BuildContext context, SemanticColors colors, MoreMenuSection section) {
  final items = moreMenu.where((item) => item.section == section).toList();
  return groupedList(colors, [
    for (var i = 0; i < items.length; i++)
      ListRow(
        icon: items[i].icon,
        label: items[i].label,
        accent: items[i].accent,
        onTap: items[i].routeName != null
            ? () => Navigator.of(context).pushNamed(items[i].routeName!)
            : null,
        badge: items[i].routeName == null
            ? const AppBadge(label: 'Coming soon', intent: 'warning')
            : null,
        showDivider: i < items.length - 1,
      ),
  ]);
}

/// More tab index: profile hero + grouped menu sections. Mirrors
/// app/(tabs)/more/index.js.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppText(
              'Account, resources & support',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppCard(
              onTap: () => Navigator.of(context).pushNamed(MoreRoutes.profile),
              child: Row(
                children: [
                  AppAvatar(name: student.name),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(student.name, variant: 'bodyBase'),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          student.registrationNumber,
                          variant: 'bodySmall',
                          tone: 'secondary',
                        ),
                      ],
                    ),
                  ),
                  Icon(Ionicons.chevron_forward, size: 18, color: colors.icon),
                ],
              ),
            ),
          ),
          for (final section in [MoreMenuSection.library, MoreMenuSection.community])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Heading(
                      level: 5,
                      tone: 'tertiary',
                      text: _sectionLabels[section]!,
                    ),
                  ),
                  _buildSectionList(context, colors, section),
                ],
              ),
            ),
          // The original reads the live app version via expo-constants
          // (`Constants.expoConfig?.version`); this port hardcodes the
          // version string as an intentional, documented simplification.
          const AppText(
            'Junaid Zaidi Library · v1.0.0',
            variant: 'caption',
            tone: 'tertiary',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
