/// Route names for the nested Navigator inside the Home tab. Home was a
/// single leaf screen until the OPAC module arrived and gave it a stack.
class HomeRoutes {
  const HomeRoutes._();

  static const String root = '/home';
}

/// Route names for the OPAC module. Book Detail isn't listed: OpacSearchScreen
/// pushes it directly with the biblio id, which keeps the id type-checked
/// instead of smuggled through `RouteSettings.arguments`.
class OpacRoutes {
  const OpacRoutes._();

  static const String search = '/opac';
}

class MoreRoutes {
  const MoreRoutes._();

  static const String root = '/more';
  static const String profile = '/more/profile';

  /// The patron module. Account-only, so both are pushed through MoreScreen's
  /// authentication check rather than directly.
  static const String myLoans = '/more/loans';
  static const String myHolds = '/more/holds';


  static const String guides = '/more/guides';
  static const String map = '/more/map';
  static const String about = '/more/about';
  static const String aboutFacts = '/more/about/facts';
  static const String aboutRules = '/more/about/rules';
  static const String aboutStaff = '/more/about/staff';
  static const String aboutFloorPlan = '/more/about/floor-plan';
}

/// Route names for the nested Navigator that AuthGate owns. Koha
/// username/password login was removed (see WelcomeScreen) — every
/// account authenticates by email now.
class AuthRoutes {
  const AuthRoutes._();

  static const String welcome = '/auth/welcome';
  static const String emailLogin = '/auth/login/email';
  static const String signupEmail = '/auth/signup/email';
  static const String verifyEmail = '/auth/signup/verify-email';
  static const String signupForm = '/auth/signup/form';
}