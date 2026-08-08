import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/library_forms.dart';
import '../data/library_images.dart';
import '../data/library_service_links.dart';
import '../navigation/app_tab_scope.dart';
import '../navigation/routes.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Services tab: core services, forms, then additional links.
class LibraryServicesScreen extends StatelessWidget {
  const LibraryServicesScreen({super.key});

  Future<void> _openExternal(
    BuildContext context,
    String url,
    String message,
  ) async {
    final confirmed = await showRedirectConfirmPopup(
      context,
      message: message,
    );
    if (!confirmed) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  String _messageForServiceUrl(String url) {
    if (url.contains('library.comsats.edu.pk')) {
      return kLibraryWebsiteRedirectMessage;
    }
    return kExternalRedirectMessage;
  }

  Future<void> _onServiceTap(
    BuildContext context,
    LibraryServiceLink service,
  ) async {
    switch (service.action) {
      case LibraryServiceAction.opac:
        AppTabScope.of(context).openSearch();
      case LibraryServiceAction.guides:
        AppTabScope.of(context).openMoreRoute(MoreRoutes.guides);
      case LibraryServiceAction.externalUrl:
        final url = service.url;
        if (url == null) return;
        await _openExternal(context, url, _messageForServiceUrl(url));
    }
  }

  Future<void> _onFormTap(BuildContext context, LibraryFormLink form) async {
    await _openExternal(context, form.url, form.confirmMessage);
  }

  List<Widget> _serviceRows(List<LibraryServiceLink> links) {
    return [
      for (var i = 0; i < links.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        Builder(
          builder: (context) {
            final service = links[i];
            final external =
                service.action == LibraryServiceAction.externalUrl;
            return ResourceRow(
              icon: service.icon,
              title: service.title,
              subtitle: service.subtitle,
              accent: service.accent,
              opensExternally: external,
              onTap: () => _onServiceTap(context, service),
            );
          },
        ),
      ],
    ];
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
            child: Heading(level: 5, text: 'Core Services'),
          ),
          ..._serviceRows(coreServiceLinks),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.ms),
            child: Heading(level: 5, text: 'Forms'),
          ),
          for (var i = 0; i < libraryForms.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final form = libraryForms[i];
                return ResourceRow(
                  icon: form.icon,
                  title: form.title,
                  subtitle: form.subtitle,
                  accent: form.accent,
                  opensExternally: true,
                  onTap: () => _onFormTap(context, form),
                );
              },
            ),
          ],
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.ms),
            child: Heading(level: 5, text: 'More'),
          ),
          ..._serviceRows(moreServiceLinks),
        ],
      ),
    );
  }
}
