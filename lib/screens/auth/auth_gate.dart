import 'package:flutter/material.dart';

import '../../models/student_request.dart';
import '../../navigation/auth_scope.dart';
import '../../navigation/routes.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/koha_auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';
import '../root_shell.dart';
import '../splash_screen.dart';
import 'email_login_screen.dart';
import 'role_selection_screen.dart';
import 'signup_form_screen.dart';
import 'staff_signup_form_screen.dart';
import 'welcome_screen.dart';

enum _AuthState { loading, authenticated, guest, signedOut }

/// Decides between the auth flow and the app itself. Four states:
///  - loading: still checking on boot.
///  - authenticated: BOTH a Koha session AND a Firebase session exist â€”
///    see _checkSession below for why "both" is required, not either.
///  - guest: no account, browsing anonymously. Persists across restarts
///    the same way a real session does (see SecureStorageService's
///    guest-mode flag) â€” a guest isn't re-prompted through Welcome every
///    launch.
///  - signedOut: none of the above â€” shows the Welcome flow.
///
/// Updated Authentication Workflow, Phase 3: login_screen.dart (the old
/// Koha-username-only screen) was deleted here, not just left unrouted â€”
/// it was already dead code with zero callers before this phase (grep
/// confirms nothing referenced it outside itself), and its username-only
/// design directly conflicts with the dual email+password login the
/// workflow doc specifies. EmailLoginScreen is now the one and only
/// login path, doing both Firebase and Koha auth together.
///
/// Route pages built here that need to navigate onward (roleSelection,
/// signupForm, staffSignupForm) do so with their OWN build context, not
/// a callback closed over this State's `context` â€” this State sits
/// above the nested auth Navigator built in `build()` below, so
/// `Navigator.of(context)` from here resolves to the app's root
/// Navigator instead of the nested one, and pushNamed calls for auth
/// routes silently fail to find a generator. Only EmailLoginScreen and
/// WelcomeScreen's guest button genuinely need a callback into this
/// State, because flipping `_state` is something only this State can
/// do â€” that's not a route navigation, so it's unaffected.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _kohaAuth = KohaAuthService();
  final _firebaseAuth = FirebaseAuthService();
  final _secureStorage = SecureStorageService();

  _AuthState _state = _AuthState.loading;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Updated Authentication Workflow, Phase 3 (Step 15's dual-login
  /// requirement extends to session restore, not just the login
  /// moment): a valid restored session requires BOTH the Koha token
  /// (secure storage) AND a live Firebase session (persisted natively
  /// by the Firebase SDK) to be present. If only one is found â€”
  /// something crashed mid-login, storage was cleared by hand, etc â€”
  /// the safest move is to clear both and force a clean re-login rather
  /// than silently trusting a half-authenticated state.
  Future<void> _checkSession() async {
    // Started before the checks, not awaited until after them, so the splash's
    // minimum on-screen time overlaps the session work instead of adding to it.
    final minimumSplash = Future<void>.delayed(SplashScreen.minimumDuration);

    final hasKohaSession = await _kohaAuth.isLoggedIn();
    final hasFirebaseSession = _firebaseAuth.currentUser != null;

    if (hasKohaSession && hasFirebaseSession) {
      await minimumSplash;
      if (mounted) setState(() => _state = _AuthState.authenticated);
      return;
    }

    if (hasKohaSession || hasFirebaseSession) {
      await _kohaAuth.logout();
      await _firebaseAuth.signOut();
    }

    final isGuest = await _secureStorage.isGuestMode();
    await minimumSplash;
    if (mounted) setState(() => _state = isGuest ? _AuthState.guest : _AuthState.signedOut);
  }

  /// Passed to EmailLoginScreen. Flips the gate over to RootShell once
  /// both Firebase and Koha login have succeeded.
  void _handleAuthenticated() {
    setState(() => _state = _AuthState.authenticated);
  }

  /// Passed to WelcomeScreen's "Continue as Guest" button.
  Future<void> _handleContinueAsGuest() async {
    await _secureStorage.setGuestMode(true);
    setState(() => _state = _AuthState.guest);
  }

  /// Exposed via AuthScope as `onLogout`. Doubles as "exit guest mode" â€”
  /// clearing all three possible states (Koha token, Firebase session,
  /// guest flag) is harmless for whichever ones weren't actually active,
  /// and correctly returns either a real user or a guest to Welcome.
  /// Updated Authentication Workflow, Phase 3 (Steps 17-19): logout
  /// clears BOTH sessions together, never just one.
  Future<void> _handleLogout() async {
    await _kohaAuth.logout();
    await _firebaseAuth.signOut();
    await _secureStorage.setGuestMode(false);
    if (mounted) setState(() => _state = _AuthState.signedOut);
  }

  Route<dynamic> _onGenerateAuthRoute(RouteSettings settings) {
    late final Widget page;
    switch (settings.name) {
      case AuthRoutes.welcome:
        page = WelcomeScreen(onContinueAsGuest: _handleContinueAsGuest);
      case AuthRoutes.emailLogin:
        page = EmailLoginScreen(onLoginSuccess: _handleAuthenticated);
      case AuthRoutes.roleSelection:
        page = const RoleSelectionScreen();
      case AuthRoutes.signupForm:
        page = const SignupFormScreen();
      case AuthRoutes.staffSignupForm:
        // Falls back to Staff if somehow reached without an argument â€”
        // RoleSelectionScreen always passes one, but a route can in
        // theory be pushed from elsewhere without it.
        final role = settings.arguments as String? ?? RegistrationRole.staff;
        page = StaffSignupFormScreen(role: role);
      default:
        page = const _ComingSoonScreen();
    }
    return MaterialPageRoute(
      // Was hardcoded to lightColors regardless of the device's actual
      // theme â€” fine in light mode, but in dark mode it left a light
      // Scaffold background showing through underneath any auth screen
      // whose content (scroll: true, e.g. RoleSelectionScreen) doesn't
      // fill the full viewport height. useTheme(context) resolves the
      // theme that's actually active, matching every other screen.
      builder: (context) =>
          Scaffold(backgroundColor: useTheme(context).background.primary, body: page),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AuthState.loading:
        return const SplashScreen();
      case _AuthState.authenticated:
        return AuthScope(onLogout: _handleLogout, isGuest: false, child: const RootShell());
      case _AuthState.guest:
        return AuthScope(onLogout: _handleLogout, isGuest: true, child: const RootShell());
      case _AuthState.signedOut:
        return Navigator(
          initialRoute: AuthRoutes.welcome,
          onGenerateRoute: _onGenerateAuthRoute,
        );
    }
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Heading(text: 'Coming soon', level: 4, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'This part of sign-up/sign-in is being built in a later phase.',
              variant: 'bodyBase',
              tone: 'secondary',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
