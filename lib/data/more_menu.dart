import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../navigation/routes.dart';
import '../theme/accents.dart';

/// Static "More" tab menu, grouped into sections. Items without a
/// `routeName` are intentionally inert per the project brief ("does
/// nothing on click" for Contact Us, Event Calendar, Junaid Zaidi Gallery)
/// and are rendered with a "Coming soon" badge instead of navigation.
/// `accent` names a semantic color used to tint each item's icon chip,
/// purely for visual categorization — not a status signal.
enum MoreMenuSection { account, library, community }

class MoreMenuItem {
  final String key;
  final String label;
  final IconData icon;
  final String? routeName;
  final MoreMenuSection section;
  final AppAccent accent;

  /// Whether a guest has to sign in first. MoreScreen shows the same prompt the
  /// Home screen's OPAC card does, instead of navigating to a screen whose data
  /// a guest is not entitled to.
  final bool requiresAuth;

  const MoreMenuItem({
    required this.key,
    required this.label,
    required this.icon,
    this.routeName,
    required this.section,
    required this.accent,
    this.requiresAuth = false,
  });
}

final List<MoreMenuItem> moreMenu = [
  const MoreMenuItem(
    key: 'my-loans',
    label: 'My Loans',
    icon: LucideIcons.book_open,
    routeName: MoreRoutes.myLoans,
    section: MoreMenuSection.account,
    accent: AppAccent.brand,
    requiresAuth: true,
  ),
  const MoreMenuItem(
    key: 'my-holds',
    label: 'My Holds',
    icon: LucideIcons.bookmark,
    routeName: MoreRoutes.myHolds,
    section: MoreMenuSection.account,
    accent: AppAccent.success,
    requiresAuth: true,
  ),
  const MoreMenuItem(
    key: 'about',
    label: 'About',
    icon: LucideIcons.info,
    routeName: MoreRoutes.about,
    section: MoreMenuSection.library,
    accent: AppAccent.brand,
  ),
  const MoreMenuItem(
    key: 'guides',
    label: 'Guides and Documentation',
    icon: LucideIcons.file,
    routeName: MoreRoutes.guides,
    section: MoreMenuSection.library,
    accent: AppAccent.success,
  ),
  const MoreMenuItem(
    key: 'map',
    label: 'Junaid Zaidi on Maps',
    icon: LucideIcons.map,
    routeName: MoreRoutes.map,
    section: MoreMenuSection.library,
    accent: AppAccent.warning,
  ),
  const MoreMenuItem(
    key: 'contact',
    label: 'Contact Us',
    icon: LucideIcons.phone,
    routeName: null,
    section: MoreMenuSection.community,
    accent: AppAccent.error,
  ),
  const MoreMenuItem(
    key: 'calendar',
    label: 'Event Calendar',
    icon: LucideIcons.calendar,
    routeName: null,
    section: MoreMenuSection.community,
    accent: AppAccent.success,
  ),
  const MoreMenuItem(
    key: 'gallery',
    label: 'Junaid Zaidi Gallery',
    icon: LucideIcons.images,
    routeName: null,
    section: MoreMenuSection.community,
    accent: AppAccent.warning,
  ),
];
