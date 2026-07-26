import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'card.dart';

/// Placeholder rows shown while a list is loading.
///
/// Deliberately mirrors [ListRow]'s anatomy and padding — icon chip on
/// the left, two stacked text lines — and sits inside the same AppCard
/// surface the real list will use, so content doesn't jump when the data
/// arrives. The slow opacity pulse is what distinguishes "loading" from
/// "rendered but broken"; a static grey block reads as the latter.
class ListSkeleton extends StatefulWidget {
  final int rows;

  const ListSkeleton({super.key, this.rows = 5});

  @override
  State<ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  /// Varied line widths per row so the block doesn't read as a table.
  static const List<double> _titleWidths = [0.72, 0.55, 0.81, 0.63, 0.75];
  static const List<double> _subtitleWidths = [0.38, 0.46, 0.32, 0.41, 0.35];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: FadeTransition(
        opacity: _opacity,
        child: Column(
          children: [
            for (var i = 0; i < widget.rows; i++)
              _skeletonRow(
                colors,
                titleWidth: _titleWidths[i % _titleWidths.length],
                subtitleWidth: _subtitleWidths[i % _subtitleWidths.length],
                showDivider: i < widget.rows - 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonRow(
    SemanticColors colors, {
    required double titleWidth,
    required double subtitleWidth,
    required bool showDivider,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.ms,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.border))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: colors.background.tertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _bar(colors, widthFactor: titleWidth, height: 12),
                const SizedBox(height: AppSpacing.sm),
                _bar(colors, widthFactor: subtitleWidth, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(
    SemanticColors colors, {
    required double widthFactor,
    required double height,
  }) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          color: colors.background.tertiary,
        ),
      ),
    );
  }
}
