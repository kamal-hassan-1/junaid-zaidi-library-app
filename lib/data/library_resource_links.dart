import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// One row on the Library Resources screen — mirrors an item from the
/// "Explore Resources" dropdown on the live library website
/// (https://library.comsats.edu.pk/), each pointing at that item's actual
/// page on the site.
class LibraryResourceLink {
  final String title;
  final String? subtitle;
  final IconData icon;
  final AppAccent accent;
  final String url;

  const LibraryResourceLink({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.url,
  });
}

final List<LibraryResourceLink> libraryResourceLinks = [
  const LibraryResourceLink(
    title: 'OPAC',
    subtitle: 'Catalog search',
    icon: LucideIcons.search,
    accent: AppAccent.brand,
    url: 'https://lib.comsats.edu.pk:82/cgi-bin/koha/opac-suggestions.pl',
  ),
  const LibraryResourceLink(
    title: 'Newspapers & Magazines',
    subtitle: 'Periodicals & print media',
    icon: LucideIcons.file_text,
    accent: AppAccent.warning,
    url: 'https://library.comsats.edu.pk/newspapers-magazines.aspx',
  ),
  const LibraryResourceLink(
    title: 'HEC Digital Library',
    subtitle: 'Research access',
    icon: LucideIcons.globe,
    accent: AppAccent.success,
    url: 'https://library.comsats.edu.pk/hec-digital-library.aspx',
  ),
  const LibraryResourceLink(
    title: 'HEC E-Books Library',
    subtitle: 'E-book access',
    icon: LucideIcons.book_open,
    accent: AppAccent.warning,
    url: 'https://library.comsats.edu.pk/hec-ebooks-library.aspx',
  ),
  const LibraryResourceLink(
    title: 'Audio/Video',
    subtitle: 'Media resources',
    icon: LucideIcons.images,
    accent: AppAccent.error,
    url: 'https://library.comsats.edu.pk/audio-video-resources.aspx',
  ),
  const LibraryResourceLink(
    title: 'Union Catalogue',
    subtitle: 'Combined library catalog',
    icon: LucideIcons.layers,
    accent: AppAccent.brand,
    url: 'https://lib.comsats.edu.pk:82/cgi-bin/koha/opac-suggestions.pl',
  ),
];