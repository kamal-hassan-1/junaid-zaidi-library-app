import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// Static Home-screen resource shortcuts. Every entry except "Explore
/// Spaces" is a static placeholder (no navigation) at this stage — per the
/// project brief, only Explore Spaces navigates anywhere right now.
class HomeResource {
  final String key;
  final String title;
  final String? subtitle;
  final IconData icon;
  final AppAccent accent;

  // The original app's data model stores a generic expo-router path string
  // per item, but only one item ever navigates anywhere (Explore Spaces),
  // and in this Flutter port that navigation is a bottom-tab switch rather
  // than a stack push — so a single boolean flag replaces the generic
  // route field for that one case.
  final bool opensExploreSpaces;

  const HomeResource({
    required this.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    this.opensExploreSpaces = false,
  });
}

final List<HomeResource> homeResources = [
  const HomeResource(
    key: 'opac',
    title: 'OPAC',
    subtitle: 'Catalog search',
    icon: LucideIcons.search,
    accent: AppAccent.brand,
  ),
  const HomeResource(
    key: 'hec-digital-library',
    title: 'HEC Digital Library',
    subtitle: 'Research access',
    icon: LucideIcons.globe,
    accent: AppAccent.success,
  ),
  const HomeResource(
    key: 'hec-ebooks-library',
    title: 'HEC E-Books Library',
    subtitle: 'E-book access',
    icon: LucideIcons.book,
    accent: AppAccent.warning,
  ),
  const HomeResource(
    key: 'cui-thesis-catalog',
    title: 'CUI Thesis Catalog',
    subtitle: 'Theses & dissertations',
    icon: LucideIcons.file_text,
    accent: AppAccent.error,
  ),
  const HomeResource(
    key: 'explore-spaces',
    title: 'Explore Spaces',
    subtitle: 'Study rooms & floors',
    icon: LucideIcons.compass,
    accent: AppAccent.brand,
    opensExploreSpaces: true,
  ),
  const HomeResource(
    key: 'student-forms',
    title: 'Student Forms',
    subtitle: 'Requests & applications',
    icon: LucideIcons.clipboard,
    accent: AppAccent.success,
  ),
];
