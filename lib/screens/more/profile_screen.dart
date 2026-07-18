import 'package:flutter/widgets.dart';
import 'package:ionicons/ionicons.dart';

import '../../data/student_profile.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Grouped list container — a card-like surface holding several [ListRow]s
/// stacked with dividers.
Widget _groupedList(SemanticColors colors, List<Widget> rows) {
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

/// Profile screen: student hero (avatar/name/reg number) + department and
/// email rows. Mirrors app/(tabs)/more/profile.js.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppAvatar(name: student.name, size: 'large'),
                const SizedBox(height: AppSpacing.sm),
                Heading(level: 4, text: student.name, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  student.registrationNumber,
                  variant: 'bodyBase',
                  tone: 'secondary',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _groupedList(colors, [
            ListRow(
              icon: Ionicons.school_outline,
              label: 'Department',
              secondaryLabel: student.department,
              showChevron: false,
            ),
            ListRow(
              icon: Ionicons.mail_outline,
              label: 'Email',
              secondaryLabel: student.email,
              showChevron: false,
              showDivider: false,
            ),
          ]),
        ],
      ),
    );
  }
}
