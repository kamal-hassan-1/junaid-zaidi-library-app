class MoreRoutes {
  const MoreRoutes._();

  static const String root = '/more';
  static const String profile = '/more/profile';
  static const String changePassword = '/more/change-password';
  static const String guides = '/more/guides';
  static const String forms = '/more/forms';
  static const String map = '/more/map';
  static const String contact = '/more/contact';
  static const String openingHours = '/more/opening-hours';
  static const String about = '/more/about';
  static const String aboutFacts = '/more/about/facts';
  static const String aboutRules = '/more/about/rules';
  static const String aboutStaff = '/more/about/staff';
  static const String aboutFloorPlan = '/more/about/floor-plan';
}

/// Nested Navigator routes for the Spaces tab.
class SpacesRoutes {
  const SpacesRoutes._();

  static const String root = '/spaces';
  static const String detail = '/spaces/detail';

  /// Named route for a specific space detail page.
  static String detailFor(String id) => '$detail/$id';
}

/// Route names for the nested Navigator that AuthGate owns.
///
/// Updated Authentication Workflow, Phase 1: signupEmail and
/// verifyEmail were removed here. The old three-screen signup
/// (email -> verify -> form) belonged to the pre-approval-gated design
/// where a temporary Firebase account existed to prove email ownership.
/// Role-aware registration: [roleSelection] sits between
/// "Create Account" and either form. It replaced a direct
/// WelcomeScreen -> signupForm hop once registration needed to branch
/// on Student vs Staff vs Teacher — see role_selection_screen.dart.
class AuthRoutes {
  const AuthRoutes._();

  static const String welcome = '/auth/welcome';
  static const String emailLogin = '/auth/login/email';
  static const String roleSelection = '/auth/signup/role';
  static const String signupForm = '/auth/signup/form';
  static const String staffSignupForm = '/auth/signup/staff';
}