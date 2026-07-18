import 'package:flutter/widgets.dart';
import 'package:ionicons/ionicons.dart';

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

class _Guide {
  final String label;
  final IconData icon;
  const _Guide(this.label, this.icon);
}

/// Static placeholder list — guide content/documents to be linked in later.
/// Kept local to this screen (not in /data), matching the original.
const List<_Guide> _guides = [
  _Guide('How to Use OPAC', Ionicons.search_outline),
  _Guide('Borrowing Policy Guide', Ionicons.book_outline),
  _Guide('Thesis Submission Guide', Ionicons.document_text_outline),
  _Guide('Digital Library Access Guide', Ionicons.globe_outline),
];

/// Guides and Documentation screen. Mirrors app/(tabs)/more/guides.js.
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: _groupedList(colors, [
        for (var i = 0; i < _guides.length; i++)
          ListRow(
            icon: _guides[i].icon,
            label: _guides[i].label,
            showChevron: false,
            showDivider: i < _guides.length - 1,
          ),
      ]),
    );
  }
}
