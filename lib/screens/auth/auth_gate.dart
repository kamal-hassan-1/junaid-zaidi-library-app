import 'package:flutter/material.dart';

import '../../navigation/auth_scope.dart';
import '../../navigation/routes.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/koha_auth_service.dart';
import '../../services/secure_storage_service.dart';
import '../../theme/semantic/light.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';
import '../root_shell.dart';
import 'email_login_screen.dart';
import 'signup_email_screen.dart';
import 'signup_form_screen.dart';
import 'verify_email_screen.dart';
import 'welcome_screen.dart';

enum _AuthState { loading, authenticated, guest, signedOut }

/// Decides between the auth flow and the app itself. Four states now,
/// not three:
///  - loading: still checking on boot.
///  - authenticated: a real session exists — Koha, Firebase email
///    (Approved), or Firebase Microsoft. See
///    FirebaseAuthService.hasApprovedRequestSession for how (2) and (3)
///    are told apart and re-validated.
///  - guest: no account, browsing anonymously. Persists across restarts
///    the same way a real session does (see SecureStorageService's
///    guest-mode flag) — a guest isn't re-prompted through Welcome every
///    launch.
///  - signedOut: none of the above — shows the Welcome flow.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _kohaAuth = KohaAuthService();
  final _firebaseAuth = FirebaseAuthService();
  final _firestoreService = FirestoreService();
  final _secureStorage = SecureStorageService();

  _AuthState _state = _AuthState.loading;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasKohaSession = await _kohaAuth.isLoggedIn();
    final hasFirebaseSession = await _firebaseAuth.hasApprovedRequestSession(_firestoreService);
    if (hasKohaSession || hasFirebaseSession) {
      if (mounted) setState(() => _state = _AuthState.authenticated);
      return;
    }

    final isGuest = await _secureStorage.isGuestMode();
    if (mounted) setState(() => _state = isGuest ? _AuthState.guest : _AuthState.signedOut);
  }

  /// Passed to LoginScreen and EmailLoginScreen. Flips the gate over to
  /// RootShell the moment either kind of login succeeds.
  void _handleAuthenticated() {
    setState(() => _state = _AuthState.authenticated);
  }

  /// Passed to WelcomeScreen's "Continue as Guest" button.
  Future<void> _handleContinueAsGuest() async {
    await _secureStorage.setGuestMode(true);
    setState(() => _state = _AuthState.guest);
  }

  /// Exposed via AuthScope as `onLogout`. Doubles as "exit guest mode" —
  /// clearing all three possible states (Koha token, Firebase session,
  /// guest flag) is harmless for whichever ones weren't actually active,
  /// and correctly returns either a real user or a guest to Welcome.
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
      case AuthRoutes.signupEmail:
        page = const SignupEmailScreen();
      case AuthRoutes.verifyEmail:
        final email = settings.arguments as String? ?? '';
        page = VerifyEmailScreen(email: email);
      case AuthRoutes.signupForm:
        page = const SignupFormScreen();
      default:
        page = const _ComingSoonScreen();
    }
    return MaterialPageRoute(
      builder: (_) => Scaffold(backgroundColor: lightColors.background.primary, body: page),
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AuthState.loading:
        return const _AuthLoadingScreen();
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

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    return ScreenContainer(
      child: Center(
        child: CircularProgressIndicator(color: colors.brand),
      ),
    );
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