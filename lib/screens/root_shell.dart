import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../navigation/app_tab_scope.dart';
import '../navigation/routes.dart';
import '../theme/theme.dart';
import 'explore_spaces_screen.dart';
import 'home_screen.dart';
import 'library_resources_screen.dart';
import 'more/about/about_screen.dart';
import 'more/about/facts_screen.dart';
import 'more/about/floor_plan_screen.dart';
import 'more/about/rules_screen.dart';
import 'more/about/staff_screen.dart';
import 'more/guides_screen.dart';
import 'more/map_screen.dart';
import 'more/more_screen.dart';
import 'more/profile_screen.dart';

/// Root navigation shell: bottom tab bar (Home / Library Resources /
/// Explore Spaces / More) mirroring app/(tabs)/_layout.js, with a nested
/// Navigator inside the More tab mirroring app/(tabs)/more/_layout.js's
/// stack. Tabs are kept alive via IndexedStack so switching tabs preserves
/// each screen's state, matching expo-router's `Tabs` behavior.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = AppTabs.home;
  final _moreNavigatorKey = GlobalKey<NavigatorState>();

  void _goToTab(int index) => setState(() => _index = index);

  // Mirrors more/_layout.js's per-screen `title` options. The "More" tab
  // root has headerShown: false there (it renders its own in-content
  // heading), so it's the only route left without a wrapping AppBar here.
  static const Map<String, String> _moreStackTitles = {
    MoreRoutes.profile: 'Profile',
    MoreRoutes.guides: 'Guides & Documentation',
    MoreRoutes.map: 'Junaid Zaidi on Maps',
    MoreRoutes.about: 'About',
    MoreRoutes.aboutFacts: 'Facts',
    MoreRoutes.aboutRules: 'Rules & Regulations',
    MoreRoutes.aboutStaff: 'Staff Info',
    MoreRoutes.aboutFloorPlan: 'Floor Plan',
  };

  Route<dynamic> _onGenerateMoreRoute(RouteSettings settings) {
    late final Widget page;
    switch (settings.name) {
      case MoreRoutes.profile:
        page = const ProfileScreen();
      case MoreRoutes.guides:
        page = const GuidesScreen();
      case MoreRoutes.map:
        page = const MapScreen();
      case MoreRoutes.about:
        page = const AboutScreen();
      case MoreRoutes.aboutFacts:
        page = const FactsScreen();
      case MoreRoutes.aboutRules:
        page = const RulesScreen();
      case MoreRoutes.aboutStaff:
        page = const StaffScreen();
      case MoreRoutes.aboutFloorPlan:
        page = const FloorPlanScreen();
      case MoreRoutes.root:
      default:
        page = const MoreScreen();
    }

    final title = _moreStackTitles[settings.name];
    final wrapped = title == null
        ? page
        : Scaffold(
            appBar: AppBar(title: Text(title)),
            body: page,
          );
    return MaterialPageRoute(builder: (_) => wrapped, settings: settings);
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    final tabs = <Widget>[
      const HomeScreen(),
      const LibraryResourcesScreen(),
      const ExploreSpacesScreen(),
      Navigator(
        key: _moreNavigatorKey,
        initialRoute: MoreRoutes.root,
        onGenerateRoute: _onGenerateMoreRoute,
      ),
    ];

    final canPopMore = _index == AppTabs.more && (_moreNavigatorKey.currentState?.canPop() ?? false);

    return AppTabScope(
      goToTab: _goToTab,
      child: PopScope(
        canPop: !canPopMore,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && canPopMore) {
            _moreNavigatorKey.currentState?.maybePop();
          }
        },
        child: Scaffold(
          body: IndexedStack(index: _index, children: tabs),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: colors.background.secondary,
              border: Border(top: BorderSide(color: colors.border, width: 1)),
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: _goToTab,
                type: BottomNavigationBarType.fixed,
                backgroundColor: colors.background.secondary,
                elevation: 0,
                selectedItemColor: colors.brand,
                unselectedItemColor: colors.icon,
                selectedLabelStyle: AppTypography.caption.toTextStyle(),
                unselectedLabelStyle: AppTypography.caption.toTextStyle(),
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(_index == AppTabs.home ? Ionicons.home : Ionicons.home_outline),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(_index == AppTabs.libraryResources ? Ionicons.library : Ionicons.library_outline),
                    label: 'Library Resources',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(_index == AppTabs.exploreSpaces ? Ionicons.compass : Ionicons.compass_outline),
                    label: 'Explore Spaces',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(_index == AppTabs.more ? Ionicons.menu : Ionicons.menu_outline),
                    label: 'More',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
