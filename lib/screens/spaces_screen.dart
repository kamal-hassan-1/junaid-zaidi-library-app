import 'package:flutter/material.dart';

import '../data/library_images.dart';
import '../data/library_spaces.dart';
import '../navigation/routes.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Spaces tab: in-app list of library spaces (same row style as Services).
class SpacesScreen extends StatelessWidget {
  const SpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      scroll: true,
      backgroundImage: const AssetImage(homeBackgroundImagePath),
      backgroundImageOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.ms),
            child: Heading(level: 5, text: 'Library Spaces'),
          ),
          for (var i = 0; i < librarySpaces.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final space = librarySpaces[i];
                return ResourceRow(
                  icon: space.icon,
                  title: space.title,
                  subtitle: space.subtitle,
                  accent: space.accent,
                  onTap: () => Navigator.of(context).pushNamed(
                    SpacesRoutes.detailFor(space.id),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
