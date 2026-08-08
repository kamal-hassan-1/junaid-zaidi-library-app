import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/library_guides.dart';
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

/// Guides and Documentation screen. Mirrors app/(tabs)/more/guides.js.
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  Future<void> _openGuide(BuildContext context, LibraryGuideLink guide) async {
    final confirmed = await showRedirectConfirmPopup(
      context,
      message: guide.confirmMessage,
    );
    if (!confirmed) return;
    await launchUrl(Uri.parse(guide.url), mode: LaunchMode.externalApplication);
  }

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
              'Download any guide provided by Junaid Zaidi Library',
              variant: 'bodySmall',
              tone: 'secondary',
            ),
          ),
          _groupedList(colors, [
            for (var i = 0; i < libraryGuides.length; i++)
              ListRow(
                icon: libraryGuides[i].icon,
                label: libraryGuides[i].title,
                accent: libraryGuides[i].accent,
                opensExternally: libraryGuides[i].opensExternally,
                onTap: () => _openGuide(context, libraryGuides[i]),
                showDivider: i < libraryGuides.length - 1,
              ),
          ]),
        ],
      ),
    );
  }
}
