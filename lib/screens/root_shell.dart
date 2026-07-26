import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
import 'opac/opac_search_screen.dart';
import 'patron/my_holds_screen.dart';
import 'patron/my_loans_screen.dart';

/// Root navigation shell: bottom tab bar (Home / Library Resources /
/// Explore Spaces / More) mirroring app/(tabs)/_layout.js, with nested
/// Navigators inside the Home and More tabs — More mirroring
/// app/(tabs)/more/_layout.js's stack, Home hosting the OPAC module. Tabs
/// are kept alive via IndexedStack so switching tabs preserves each screen's
/// state, matching expo-router's `Tabs` behavior.
///
/// Pushing OPAC inside the Home tab (rather than over the whole shell) is
/// what keeps the bottom bar visible throughout the catalog, and what lets
/// Book Detail pop back to a still-live search results list.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = AppTabs.home;
  final _homeNavigatorKey = GlobalKey<NavigatorState>();
  final _moreNavigatorKey = GlobalKey<NavigatorState>();

  // One observer per Navigator — a NavigatorObserver binds itself to a single
  // Navigator, so they can't be shared.
  late final _NestedStackObserver _homeObserver;
  late final _NestedStackObserver _moreObserver;

  @override
  void initState() {
    super.initState();
    _homeObserver = _NestedStackObserver(_handleNestedStackChanged);
    _moreObserver = _NestedStackObserver(_handleNestedStackChanged);
  }

  void _goToTab(int index) => setState(() => _index = index);

  /// PopScope decides `canPop` at build time, so the shell has to rebuild
  /// whenever a nested stack changes depth — otherwise the system back
  /// button acts on a stale answer and pops the whole app instead of the
  /// current tab's stack. Deferred to after the frame because observers also
  /// fire while a Navigator is installing its initial route, mid-build.
  void _handleNestedStackChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// The tabs that own a stack; the other two are single screens.
  GlobalKey<NavigatorState>? get _activeNestedNavigator => switch (_index) {
    AppTabs.home => _homeNavigatorKey,
    AppTabs.more => _moreNavigatorKey,
    _ => null,
  };

  Route<dynamic> _onGenerateHomeRoute(RouteSettings settings) {
    late final Widget page;
    switch (settings.name) {
      case OpacRoutes.search:
        page = const OpacSearchScreen();
      case HomeRoutes.root:
      default:
        page = const HomeScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  /// A tab's Navigator, pinned to a single initial route.
  ///
  /// [Navigator.defaultGenerateInitialRoutes] expands a path-style
  /// `initialRoute` into one route per '/' segment, so '/more' quietly built
  /// a second MoreScreen underneath the first (both '/' and '/more' fall
  /// through to the generator's default case). That left `canPop()` stuck on
  /// true, breaking the back-button handling below.
  Widget _nestedNavigator({
    required GlobalKey<NavigatorState> key,
    required NavigatorObserver observer,
    required String initialRoute,
    required Route<dynamic> Function(RouteSettings) onGenerateRoute,
  }) {
    return Navigator(
      key: key,
      observers: [observer],
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      onGenerateInitialRoutes: (_, _) => [
        onGenerateRoute(RouteSettings(name: initialRoute)),
      ],
    );
  }

  // Mirrors more/_layout.js's per-screen `title` options. The "More" tab
  // root has headerShown: false there (it renders its own in-content
  // heading), so it's the only route left without a wrapping AppBar here.
  static const Map<String, String> _moreStackTitles = {
    MoreRoutes.profile: 'Profile',
    MoreRoutes.myLoans: 'My Loans',
    MoreRoutes.myHolds: 'My Holds',
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
      case MoreRoutes.myLoans:
        page = const MyLoansScreen();
      case MoreRoutes.myHolds:
        page = const MyHoldsScreen();
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
      _nestedNavigator(
        key: _homeNavigatorKey,
        observer: _homeObserver,
        initialRoute: HomeRoutes.root,
        onGenerateRoute: _onGenerateHomeRoute,
      ),
      const LibraryResourcesScreen(),
      const ExploreSpacesScreen(),
      _nestedNavigator(
        key: _moreNavigatorKey,
        observer: _moreObserver,
        initialRoute: MoreRoutes.root,
        onGenerateRoute: _onGenerateMoreRoute,
      ),
    ];

    // Back unwinds the active tab's stack first, and only leaves the app once
    // that tab is back at its root.
    final nestedNavigator = _activeNestedNavigator;
    final canPopNested = nestedNavigator?.currentState?.canPop() ?? false;

    return AppTabScope(
      goToTab: _goToTab,
      child: PopScope(
        canPop: !canPopNested,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            nestedNavigator?.currentState?.maybePop();
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
                    icon: Icon(LucideIcons.house),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.library),
                    label: 'Library Resources',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.compass),
                    label: 'Explore Spaces',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.menu),
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

/// Reports every depth change in a tab's stack so RootShell can recompute
/// whether the back button belongs to that tab or to the OS.
class _NestedStackObserver extends NavigatorObserver {
  final VoidCallback onChanged;

  _NestedStackObserver(this.onChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onChanged();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => onChanged();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => onChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => onChanged();
}
