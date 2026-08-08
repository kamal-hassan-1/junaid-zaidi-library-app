import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/library_images.dart';
import '../data/library_resource_links.dart';
import '../navigation/app_tab_scope.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Services tab: the same 6 items as the "Explore Resources" dropdown on
/// the live library website, one per row. OPAC opens the Search tab; every
/// other item opens that resource's page on the library website.
class LibraryResourcesScreen extends StatelessWidget {
  const LibraryResourcesScreen({super.key});

  Future<void> _openWebsite(BuildContext context, String url) async {
    final confirmed = await showRedirectConfirmPopup(
      context,
      message: kLibraryWebsiteRedirectMessage,
    );
    if (!confirmed) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
            child: Heading(level: 5, text: 'Services'),
          ),
          for (var i = 0; i < libraryResourceLinks.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final resource = libraryResourceLinks[i];
                final isOpac = resource.title == 'OPAC';
                return ResourceRow(
                  icon: resource.icon,
                  title: resource.title,
                  subtitle: resource.subtitle,
                  accent: resource.accent,
                  opensExternally: !isOpac,
                  onTap: isOpac
                      ? () => AppTabScope.of(context).openSearch()
                      : () => _openWebsite(context, resource.url),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
