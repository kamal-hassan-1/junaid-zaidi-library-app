import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/library_images.dart';
import '../widgets/ui.dart';

/// Explore Spaces tab. Under construction — mirrors
/// app/(tabs)/explore-spaces.js.
class ExploreSpacesScreen extends StatelessWidget {
  const ExploreSpacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenContainer(
      backgroundImage: AssetImage(homeBackgroundImagePath),
      backgroundImageOpacity: 0.2,
      child: EmptyState(
        icon: LucideIcons.compass,
        title: 'Explore Spaces',
        description:
            'This section is under construction. Study rooms and floor spaces will appear here soon.',
      ),
    );
  }
}
