import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/library_images.dart';
import '../data/library_resource_links.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';
import 'opac.dart';

/// Library Resources tab: the same 6 items as the "Explore Resources"
/// dropdown on the live library website, one per row. OPAC opens the in-app
/// catalog search; every other item opens that resource's page on the
/// library website.
class LibraryResourcesScreen extends StatelessWidget {
  const LibraryResourcesScreen({super.key});

  Future<void> _openWebsite(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openOpac(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpacScreen()),
    );
  }

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
            child: Heading(level: 5, text: 'Library Resources'),
          ),
          for (var i = 0; i < libraryResourceLinks.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final resource = libraryResourceLinks[i];
                return ResourceRow(
                  icon: resource.icon,
                  title: resource.title,
                  subtitle: resource.subtitle,
                  accent: resource.accent,
                  onTap: resource.title == 'OPAC'
                      ? () => _openOpac(context)
                      : () => _openWebsite(resource.url),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
