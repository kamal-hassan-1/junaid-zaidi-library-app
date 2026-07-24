import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/library_images.dart';
import '../widgets/ui.dart';

/// Library Resources tab. Under construction — mirrors
/// app/(tabs)/library-resources.js.
class LibraryResourcesScreen extends StatelessWidget {
  const LibraryResourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScreenContainer(
      backgroundImage: AssetImage(homeBackgroundImagePath),
      backgroundImageOpacity: 0.2,
      child: EmptyState(
        icon: LucideIcons.library,
        title: 'Library Resources',
        description:
            'This section is under construction. Resource listings will appear here soon.',
      ),
    );
  }
}
