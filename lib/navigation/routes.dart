/// Route names for the nested Navigator that lives inside the "More"
/// bottom tab (mirrors the original app's `app/(tabs)/more/*` expo-router
/// stack).
class MoreRoutes {
  const MoreRoutes._();

  static const String root = '/more';
  static const String profile = '/more/profile';
  static const String guides = '/more/guides';
  static const String map = '/more/map';
  static const String about = '/more/about';
  static const String aboutFacts = '/more/about/facts';
  static const String aboutRules = '/more/about/rules';
  static const String aboutStaff = '/more/about/staff';
  static const String aboutFloorPlan = '/more/about/floor-plan';
}

/// Route names for the nested Navigator that AuthGate owns (added
/// Phase 2). Screens push these by name rather than by direct widget
/// reference, since welcome_screen.dart (Phase 2) is written before
/// login_screen.dart / signup_email_screen.dart (Phases 3 and 5) exist —
/// named routes let each phase stay independently compilable.
class AuthRoutes {
  const AuthRoutes._();

  static const String welcome = '/auth/welcome';
  static const String login = '/auth/login';
  static const String signupEmail = '/auth/signup/email';
  static const String verifyEmail = '/auth/signup/verify-email';
  static const String signupForm = '/auth/signup/form';
}