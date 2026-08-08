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

/// Route names for the nested Navigator that AuthGate owns.
///
/// Updated Authentication Workflow, Phase 1: signupEmail and
/// verifyEmail were removed here. The old three-screen signup
/// (email -> verify -> form) belonged to the pre-approval-gated design
/// where a temporary Firebase account existed to prove email ownership.
/// The workflow this app now implements does registration in one
/// screen with format-only validation and no account of any kind until
/// a librarian approves the request — see signup_form_screen.dart.
class AuthRoutes {
  const AuthRoutes._();

  static const String welcome = '/auth/welcome';
  static const String emailLogin = '/auth/login/email';
  static const String signupForm = '/auth/signup/form';
}