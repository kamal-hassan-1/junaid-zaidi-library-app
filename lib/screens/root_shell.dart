import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../navigation/app_tab_scope.dart';
import '../navigation/routes.dart';
import '../theme/theme.dart';
import 'explore_spaces_screen.dart';
import 'home_screen.dart';
import 'library_services_screen.dart';
import 'more/about/about_screen.dart';
import 'more/about/facts_screen.dart';
import 'more/about/floor_plan_screen.dart';
import 'more/about/rules_screen.dart';
import 'more/about/staff_screen.dart';
import 'more/contact_us_screen.dart';
import 'more/forms_screen.dart';
import 'more/guides_screen.dart';
import 'more/map_screen.dart';
import 'more/more_screen.dart';
import 'more/opening_hours_screen.dart';
import 'more/profile_screen.dart';
import 'more/request_password_change_screen.dart';
import 'opac.dart';

/// Root navigation shell: bottom tab bar (Home / Search / Services /
/// Spaces / More), with a nested Navigator inside the More tab. Tabs are
/// kept alive via IndexedStack so switching tabs preserves each screen's
/// state.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = AppTabs.home;
  GlobalKey<NavigatorState> _moreNavigatorKey = GlobalKey<NavigatorState>();
  String? _opacQuery;
  int _opacQueryGeneration = 0;

  /// Drop the More stack instantly by remounting its Navigator.
  /// Avoids the pop-animation flash of the previous nested screen.
  void _resetMoreStack() {
    _moreNavigatorKey = GlobalKey<NavigatorState>();
  }

  void _goToTab(int index) {
    // Selecting More always lands on the menu root — both when switching
    // from another tab (stack was preserved by IndexedStack) and when
    // re-tapping More while nested.
    if (index == AppTabs.more) {
      final needsReset = _moreNavigatorKey.currentState?.canPop() ?? false;
      setState(() {
        _index = index;
        if (needsReset) _resetMoreStack();
      });
      return;
    }
    setState(() => _index = index);
  }

  void _openSearch([String? query]) {
    setState(() {
      _index = AppTabs.search;
      if (query != null) {
        _opacQuery = query;
        _opacQueryGeneration++;
      }
    });
  }

  /// Open a More stack screen from another tab (e.g. Home quick links).
  ///
  /// Remounts the More navigator offstage, pushes the destination with no
  /// transition, then shows the More tab — so neither the menu nor a prior
  /// nested screen flashes.
  void _openMoreRoute(String routeName) {
    setState(_resetMoreStack);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _moreNavigatorKey.currentState?.push(
        _buildMoreRoute(RouteSettings(name: routeName), instant: true),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _index = AppTabs.more);
      });
    });
  }

  // Mirrors more/_layout.js's per-screen `title` options. The "More" tab
  // root has headerShown: false there (it renders its own in-content
  // heading), so it's the only route left without a wrapping AppBar here.
  static const Map<String, String> _moreStackTitles = {
    MoreRoutes.profile: 'Profile',
    MoreRoutes.changePassword: 'Request Password Change',
    MoreRoutes.guides: 'Guides & Documentation',
    MoreRoutes.forms: 'Forms',
    MoreRoutes.map: 'Junaid Zaidi on Maps',
    MoreRoutes.contact: 'Contact Us',
    MoreRoutes.openingHours: 'Opening Hours',
    MoreRoutes.about: 'About',
    MoreRoutes.aboutFacts: 'Facts',
    MoreRoutes.aboutRules: 'Rules & Regulations',
    MoreRoutes.aboutStaff: 'Staff Info',
    MoreRoutes.aboutFloorPlan: 'Floor Plan',
  };

  Widget _pageForMoreRoute(String? name) {
    switch (name) {
      case MoreRoutes.profile:
        return const ProfileScreen();
      case MoreRoutes.changePassword:
        return const RequestPasswordChangeScreen();
      case MoreRoutes.guides:
        return const GuidesScreen();
      case MoreRoutes.forms:
        return const FormsScreen();
      case MoreRoutes.map:
        return const MapScreen();
      case MoreRoutes.contact:
        return const ContactUsScreen();
      case MoreRoutes.openingHours:
        return const OpeningHoursScreen();
      case MoreRoutes.about:
        return const AboutScreen();
      case MoreRoutes.aboutFacts:
        return const FactsScreen();
      case MoreRoutes.aboutRules:
        return const RulesScreen();
      case MoreRoutes.aboutStaff:
        return const StaffScreen();
      case MoreRoutes.aboutFloorPlan:
        return const FloorPlanScreen();
      case MoreRoutes.root:
      default:
        return const MoreScreen();
    }
  }

  Route<dynamic> _buildMoreRoute(
    RouteSettings settings, {
    bool instant = false,
  }) {
    final page = _pageForMoreRoute(settings.name);
    final title = _moreStackTitles[settings.name];
    final wrapped = title == null
        ? page
        : Scaffold(
            appBar: AppBar(title: Text(title)),
            body: page,
          );

    if (instant) {
      return PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => wrapped,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }
    return MaterialPageRoute<void>(builder: (_) => wrapped, settings: settings);
  }

  Route<dynamic> _onGenerateMoreRoute(RouteSettings settings) {
    return _buildMoreRoute(settings);
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    final tabs = <Widget>[
      const HomeScreen(),
      OpacScreen(
        initialQuery: _opacQuery,
        queryGeneration: _opacQueryGeneration,
      ),
      const LibraryServicesScreen(),
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
      openSearch: _openSearch,
      openMoreRoute: _openMoreRoute,
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
                    icon: Icon(LucideIcons.house),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.search),
                    label: 'Search',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.library),
                    label: 'Services',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(LucideIcons.compass),
                    label: 'Spaces',
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