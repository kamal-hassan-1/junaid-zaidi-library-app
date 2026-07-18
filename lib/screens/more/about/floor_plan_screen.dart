import 'package:flutter/widgets.dart';

import '../../../theme/theme.dart';
import '../../../widgets/ui.dart';

class _Floor {
  final String label;
  final String assetPath;

  const _Floor(this.label, this.assetPath);
}

const List<_Floor> _floors = [
  _Floor('Ground Floor', 'assets/library-ground-floor.jpg'),
  _Floor('First Floor', 'assets/library-firstFloor.jpg'),
];

/// Floor Plan (mirrors `app/(tabs)/more/about/floor-plan.js`): a heading +
/// full-width photo per floor. The floor list is kept local to this screen,
/// matching the original.
class FloorPlanScreen extends StatelessWidget {
  const FloorPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final floor in _floors)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Heading(level: 5, text: floor.label),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.asset(
                      floor.assetPath,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
