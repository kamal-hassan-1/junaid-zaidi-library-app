import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../theme/accents.dart';

/// Home-screen shortcut cards (2-column grid).
enum HomeResourceAction {
  opac,
  patronProfile,
  hecDigitalLibrary,
  openingHours,
  accessWebsite,
  aboutJzl,
}

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
    required this.action,
  });
}

final List<HomeResource> homeResources = [
  const HomeResource(
    key: 'opac',
    title: 'OPAC',
    subtitle: 'Catalog search',
    icon: LucideIcons.search,
    accent: AppAccent.brand,
    action: HomeResourceAction.opac,
  ),
  const HomeResource(
    key: 'patron-profile',
    title: 'Patron Profile',
    subtitle: 'Your account',
    icon: LucideIcons.user,
    accent: AppAccent.success,
    action: HomeResourceAction.patronProfile,
  ),
  const HomeResource(
    key: 'hec-digital-library',
    title: 'HEC Digital Library',
    subtitle: 'Research access',
    icon: LucideIcons.globe,
    accent: AppAccent.warning,
    action: HomeResourceAction.hecDigitalLibrary,
  ),
  const HomeResource(
    key: 'opening-hours',
    title: 'Opening Hours',
    subtitle: 'When we\'re open',
    icon: LucideIcons.clock,
    accent: AppAccent.error,
    action: HomeResourceAction.openingHours,
  ),
  const HomeResource(
    key: 'access-website',
    title: 'Access Website',
    subtitle: 'library.comsats.edu.pk',
    icon: LucideIcons.external_link,
    accent: AppAccent.brand,
    action: HomeResourceAction.accessWebsite,
  ),
  const HomeResource(
    key: 'about-jzl',
    title: 'About JZL',
    subtitle: 'Library overview',
    icon: LucideIcons.info,
    accent: AppAccent.success,
    action: HomeResourceAction.aboutJzl,
  ),
];
