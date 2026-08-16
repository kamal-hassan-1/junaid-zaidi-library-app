import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../data/library_spaces.dart';
import '../navigation/app_tab_scope.dart';
import '../navigation/routes.dart';
import '../theme/theme.dart';
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
import 'more/my_books_screen.dart';
import 'more/opening_hours_screen.dart';
import 'more/profile_screen.dart';
import 'more/request_password_change_screen.dart';
import 'opac.dart';
import 'space_detail_screen.dart';
import 'spaces_screen.dart';

/// Root navigation shell: bottom tab bar (Home / Search / Services /
/// Spaces / More), with nested Navigators inside the Spaces and More tabs.
/// Tabs are kept alive via IndexedStack so switching tabs preserves each
/// screen's state.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = AppTabs.home;
  GlobalKey<NavigatorState> _spacesNavigatorKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> _moreNavigatorKey = GlobalKey<NavigatorState>();
  String? _opacQuery;
  int _opacQueryGeneration = 0;
  DateTime? _lastBackPressAt;

  bool _canPopSpacesNavigator() =>
      _spacesNavigatorKey.currentState?.canPop() ?? false;

  bool _canPopMoreNavigator() =>
      _moreNavigatorKey.currentState?.canPop() ?? false;

  void _handleBackPress() {
    if (_index == AppTabs.spaces && _canPopSpacesNavigator()) {
      _spacesNavigatorKey.currentState!.pop();
      return;
    }
    if (_index == AppTabs.more && _canPopMoreNavigator()) {
      _moreNavigatorKey.currentState!.pop();
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressAt == null ||
        now.difference(_lastBackPressAt!) > const Duration(seconds: 2)) {
      _lastBackPressAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    SystemNavigator.pop();
  }

  /// Drop the Spaces stack instantly by remounting its Navigator.
  void _resetSpacesStack() {
    _spacesNavigatorKey = GlobalKey<NavigatorState>();
  }

  /// Drop the More stack instantly by remounting its Navigator.
  /// Avoids the pop-animation flash of the previous nested screen.
  void _resetMoreStack() {
    _moreNavigatorKey = GlobalKey<NavigatorState>();
  }

  void _goToTab(int index) {
    // Selecting Spaces or More always lands on the menu root — both when
    // switching from another tab and when re-tapping while nested.
    if (index == AppTabs.spaces) {
      final needsReset = _spacesNavigatorKey.currentState?.canPop() ?? false;
      setState(() {
        _index = index;
        if (needsReset) _resetSpacesStack();
      });
      return;
    }
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
    MoreRoutes.myBooks: 'My Checkouts & Holds',
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
      case MoreRoutes.myBooks:
        return const MyBooksScreen();
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

  Route<dynamic> _onGenerateSpacesRoute(RouteSettings settings) {
    final name = settings.name;
    if (name != null && name.startsWith('${SpacesRoutes.detail}/')) {
      final id = name.substring(SpacesRoutes.detail.length + 1);
      final space = librarySpaceById(id);
      if (space != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(space.title)),
            body: SpaceDetailScreen(space: space),
          ),
        );
      }
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const SpacesScreen(),
    );
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
      Navigator(
        key: _spacesNavigatorKey,
        initialRoute: SpacesRoutes.root,
        onGenerateRoute: _onGenerateSpacesRoute,
      ),
      Navigator(
        key: _moreNavigatorKey,
        initialRoute: MoreRoutes.root,
        onGenerateRoute: _onGenerateMoreRoute,
      ),
    ];

    return AppTabScope(
      goToTab: _goToTab,
      openSearch: _openSearch,
      openMoreRoute: _openMoreRoute,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackPress();
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
