import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'app_text.dart';

/// A row of pill-shaped, tappable labels — the mobile stand-in for the
/// index dropdown in Koha's OPAC masthead, and reusable anywhere a short
/// set of options needs to stay visible rather than hide behind a picker.
///
/// [selectedIndex] is nullable on purpose: pass null when the pills are
/// shortcuts rather than a choice (recent searches), so none render as
/// active. Set [wrap] when the labels are user-supplied and can't be
/// relied on to fit a single scrolling line.
class AppFilterChips extends StatelessWidget {
  final List<String> labels;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final bool wrap;

  const AppFilterChips({
    super.key,
    required this.labels,
    required this.onSelected,
    this.selectedIndex,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    if (wrap) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var i = 0; i < labels.length; i++) _chip(colors, i),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            _chip(colors, i),
          ],
        ],
      ),
    );
  }

  Widget _chip(SemanticColors colors, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: isSelected,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.ms,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? colors.brand : colors.background.secondary,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: isSelected ? colors.brand : colors.border,
              width: 1,
            ),
          ),
          child: AppText(
            labels[index],
            variant: 'bodySmall',
            tone: isSelected ? 'onBrand' : 'secondary',
          ),
        ),
      ),
    );
  }
}
