import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// How a Services-tab row behaves when tapped.
enum LibraryServiceAction {
  /// Switch to the Search (OPAC) tab.
  opac,

  /// Confirm + open [LibraryServiceLink.url] externally.
  externalUrl,

  /// Open Guides & Documentation in the More stack.
  guides,
}

/// One row on the Services tab.
class LibraryServiceLink {
  final String title;
  final String? subtitle;
  final IconData icon;
  final AppAccent accent;
  final LibraryServiceAction action;
  final String? url;

  const LibraryServiceLink({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.action,
    this.url,
  });
}

/// Primary services shown under "Core Services".
final List<LibraryServiceLink> coreServiceLinks = [
  const LibraryServiceLink(
    title: 'OPAC',
    subtitle: 'Catalog search',
    icon: LucideIcons.search,
    accent: AppAccent.brand,
    action: LibraryServiceAction.opac,
  ),
  const LibraryServiceLink(
    title: 'CUI Thesis Catalog',
    subtitle: 'Theses & suggestions',
    icon: LucideIcons.graduation_cap,
    accent: AppAccent.success,
    action: LibraryServiceAction.externalUrl,
    url: 'https://lib.comsats.edu.pk:82/cgi-bin/koha/opac-suggestions.pl',
  ),
  const LibraryServiceLink(
    title: 'Newspapers & Magazines',
    subtitle: 'Periodicals & print media',
    icon: LucideIcons.file_text,
    accent: AppAccent.warning,
    action: LibraryServiceAction.externalUrl,
    url: 'https://library.comsats.edu.pk/newspapers-magazines.aspx',
  ),
  const LibraryServiceLink(
    title: 'HEC Digital Library',
    subtitle: 'Research access',
    icon: LucideIcons.globe,
    accent: AppAccent.success,
    action: LibraryServiceAction.externalUrl,
    url: 'https://library.comsats.edu.pk/hec-digital-library.aspx',
  ),
  const LibraryServiceLink(
    title: 'HEC E-Books Library',
    subtitle: 'E-book access',
    icon: LucideIcons.book_open,
    accent: AppAccent.warning,
    action: LibraryServiceAction.externalUrl,
    url: 'https://library.comsats.edu.pk/hec-ebooks-library.aspx',
  ),
];

/// Secondary services shown under the "More" subsection (after Forms).
final List<LibraryServiceLink> moreServiceLinks = [
  const LibraryServiceLink(
    title: 'Audio/Video',
    subtitle: 'Media resources',
    icon: LucideIcons.images,
    accent: AppAccent.error,
    action: LibraryServiceAction.externalUrl,
    url: 'https://library.comsats.edu.pk/audio-video-resources.aspx',
  ),
  const LibraryServiceLink(
    title: 'Union Catalogue',
    subtitle: 'Combined library catalog',
    icon: LucideIcons.layers,
    accent: AppAccent.brand,
    action: LibraryServiceAction.externalUrl,
    url: 'https://lib.comsats.edu.pk:82/cgi-bin/koha/opac-suggestions.pl',
  ),
  const LibraryServiceLink(
    title: 'Guides',
    subtitle: 'Guides & documentation',
    icon: LucideIcons.file,
    accent: AppAccent.success,
    action: LibraryServiceAction.guides,
  ),
];
