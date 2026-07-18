import 'package:flutter/widgets.dart';

import '../../../data/about_content.dart';
import '../../../theme/theme.dart';
import '../../../widgets/ui.dart';

/// Staff Info (mirrors `app/(tabs)/more/about/staff.js`): a simple
/// avatar + name/role directory list, divided between rows.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      scroll: true,
      child: Column(
        children: [
          for (var i = 0; i < staffDirectory.length; i++)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms),
                  child: Row(
                    children: [
                      AppAvatar(name: staffDirectory[i].name),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(staffDirectory[i].name, variant: 'bodyBase'),
                          AppText(
                            staffDirectory[i].role,
                            variant: 'bodySmall',
                            tone: 'secondary',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i < staffDirectory.length - 1) const AppDivider(),
              ],
            ),
        ],
      ),
    );
  }
}
