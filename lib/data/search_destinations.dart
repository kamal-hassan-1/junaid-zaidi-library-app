import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../navigation/app_tab_scope.dart';
import '../navigation/auth_scope.dart';
import '../navigation/routes.dart';
import '../widgets/ui.dart';
import 'more_menu.dart';

/// A non-catalog destination the Home search bar can jump to directly when
/// the typed query matches one of [keywords]. See [matchSearchDestinations].
class SearchDestination {
  final String label;
  final IconData icon;
  final List<String> keywords;
  final Future<void> Function(BuildContext context) navigate;

  const SearchDestination({
    required this.label,
    required this.icon,
    required this.keywords,
    required this.navigate,
  });
}

/// Extra keywords per [moreMenu] item — beyond its literal label — that a
/// user might actually type ("hours" for Opening Hours, "vpn" for Guides).
const Map<String, List<String>> _moreMenuKeywords = {
  'my-books': [
    'borrow',
    'borrowing',
    'checkout',
    'checkouts',
    'my books',
    'hold',
    'holds',
    'reserve',
    'reservation',
    'renew',
    'renewal',
    'due',
  ],
  'about': ['about', 'facts', 'rules', 'regulations', 'staff', 'floor plan'],
  'opening-hours': ['hours', 'timing', 'timings', 'open', 'schedule'],
  'guides': ['guide', 'guides', 'handbook', 'turnitin', 'vpn', 'documentation'],
  'forms': ['form', 'forms', 'application', 'plagiarism', 'membership'],
  'map': ['map', 'location', 'directions'],
  'contact': ['contact', 'phone', 'email', 'address'],
};

/// Every destination the Home search bar can route to, beyond an OPAC
/// catalog search. Reuses [moreMenu]'s label/icon/route for the More-tab
/// items so this list can't drift out of sync with the real More menu, and
/// adds the handful of destinations that live outside the More tab.
List<SearchDestination> buildSearchDestinations() => [
      for (final item in moreMenu)
        SearchDestination(
          label: item.label,
          icon: item.icon,
          keywords: _moreMenuKeywords[item.key] ?? [item.label.toLowerCase()],
          navigate: (context) async =>
              AppTabScope.of(context).openMoreRoute(item.routeName!),
        ),
      SearchDestination(
        label: 'Your Profile',
        icon: LucideIcons.user,
        keywords: ['profile', 'account', 'membership'],
        navigate: (context) async {
          final auth = AuthScope.of(context);
          if (auth.isGuest) {
            final go = await showRedirectConfirmPopup(
              context,
              title: 'Sign in required',
              message:
                  'Sign up or log in to view your patron profile. Guests do not have a library account profile.',
              confirmLabel: 'Sign Up / Sign In',
            );
            if (go && context.mounted) await auth.onLogout();
            return;
          }
          AppTabScope.of(context).openMoreRoute(MoreRoutes.profile);
        },
      ),
      SearchDestination(
        label: 'Library Services',
        icon: LucideIcons.library,
        keywords: [
          'service',
          'services',
          'ebook',
          'e-book',
          'ebooks',
          'newspaper',
          'magazine',
          'thesis',
        ],
        navigate: (context) async =>
            AppTabScope.of(context).goToTab(AppTabs.services),
      ),
      SearchDestination(
        label: 'Spaces',
        icon: LucideIcons.compass,
        keywords: [
          'space',
          'spaces',
          'room',
          'rooms',
          'study room',
          'cubicle',
          'reading corner',
        ],
        navigate: (context) async =>
            AppTabScope.of(context).goToTab(AppTabs.spaces),
      ),
    ];

/// Case-insensitive keyword match against [destinations], ranking prefix
/// matches ("form" -> "forms") above mid-string matches, capped to [limit]
/// so the suggestion dropdown stays short.
List<SearchDestination> matchSearchDestinations(
  String query,
  List<SearchDestination> destinations, {
  int limit = 4,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final prefixMatches = <SearchDestination>[];
  final substringMatches = <SearchDestination>[];

  for (final dest in destinations) {
    final isPrefix = dest.keywords.any((k) => k.startsWith(q));
    if (isPrefix) {
      prefixMatches.add(dest);
      continue;
    }
    if (dest.keywords.any((k) => k.contains(q))) {
      substringMatches.add(dest);
    }
  }

  return [...prefixMatches, ...substringMatches].take(limit).toList();
}
