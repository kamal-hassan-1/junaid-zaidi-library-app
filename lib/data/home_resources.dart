import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// What tapping a Home resource card does. The original app stored a generic
/// expo-router path per item, but the destinations here aren't uniform — one
/// switches bottom tabs, one pushes onto the Home stack behind an auth check,
/// and the rest are still placeholders — so HomeScreen resolves each case
/// explicitly instead.
enum HomeResourceAction {
  /// Static card, not tappable yet.
  none,
  exploreSpacesTab,
  opacSearch,
}

/// Static Home-screen resource shortcuts. The HEC libraries, thesis catalog
/// and student forms entries are still placeholders at this stage.
class HomeResource {
  final String key;
  final String title;
  final String? subtitle;
  final IconData icon;
  final AppAccent accent;
  final HomeResourceAction action;

  const HomeResource({
    required this.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    this.action = HomeResourceAction.none,
  });
}

final List<HomeResource> homeResources = [
  const HomeResource(
    key: 'opac',
    title: 'OPAC',
    subtitle: 'Catalog search',
    icon: LucideIcons.search,
    accent: AppAccent.brand,
    action: HomeResourceAction.opacSearch,
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
    action: HomeResourceAction.exploreSpacesTab,
  ),
  const HomeResource(
    key: 'student-forms',
    title: 'Student Forms',
    subtitle: 'Requests & applications',
    icon: LucideIcons.clipboard,
    accent: AppAccent.success,
  ),
];
