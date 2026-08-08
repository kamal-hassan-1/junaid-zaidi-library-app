import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../firebase_bootstrap.dart' show firebaseReady;
import '../../navigation/auth_scope.dart';
import '../../navigation/routes.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/koha_auth_service.dart';
import '../../services/onboarding_prefs.dart';
import '../../services/secure_storage_service.dart';
import '../../theme/semantic/light.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';
import '../onboarding/onboarding_screen.dart';
import '../root_shell.dart';
import '../splash_screen.dart';
import 'email_login_screen.dart';
import 'signup_form_screen.dart';
import 'welcome_screen.dart';

enum _AuthState { loading, onboarding, authenticated, guest, signedOut }

/// Decides between the auth flow and the app itself. Five states:
///  - loading: [SplashScreen] over a matching plate; native OS splash is
///    background-only and is removed when SplashScreen paints.
///  - onboarding: first launch — [OnboardingScreen] until Get Started / Skip.
///  - authenticated: BOTH a Koha session AND a Firebase session exist —
///    see _checkSession below for why "both" is required, not either.
///  - guest: no account, browsing anonymously. Persists across restarts
///    the same way a real session does (see SecureStorageService's
///    guest-mode flag) — a guest isn't re-prompted through Welcome every
///    launch.
///  - signedOut: none of the above — shows the Welcome flow.
///
/// Updated Authentication Workflow, Phase 3: login_screen.dart (the old
/// Koha-username-only screen) was deleted here, not just left unrouted —
/// it was already dead code with zero callers before this phase (grep
/// confirms nothing referenced it outside itself), and its username-only
/// design directly conflicts with the dual email+password login the
/// workflow doc specifies. EmailLoginScreen is now the one and only
/// login path, doing both Firebase and Koha auth together.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _kohaAuth = KohaAuthService();
  final _firebaseAuth = FirebaseAuthService();
  final _secureStorage = SecureStorageService();
  final _onboardingPrefs = OnboardingPrefs();

  _AuthState _state = _AuthState.loading;

  /// Session outcome while onboarding may still need to run first.
  _AuthState? _pendingAfterOnboarding;

  /// Splash stays mounted over the destination until it fades out.
  bool _splashMounted = true;
  double _splashOpacity = 1;

  @override
  void initState() {
    super.initState();
    // Safety: dismiss native plate even if SplashScreen is slow to mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _checkSession();
  }

  /// Updated Authentication Workflow, Phase 3 (Step 15's dual-login
  /// requirement extends to session restore, not just the login
  /// moment): a valid restored session requires BOTH the Koha token
  /// (secure storage) AND a live Firebase session (persisted natively
  /// by the Firebase SDK) to be present. If only one is found —
  /// something crashed mid-login, storage was cleared by hand, etc —
  /// the safest move is to clear both and force a clean re-login rather
  /// than silently trusting a half-authenticated state.
  Future<void> _checkSession() async {
    final started = DateTime.now();

    try {
      // Firebase starts in main() without blocking the first frame; wait here
      // before reading Auth / session state. Time out so a hung init can't
      // pin the app on the splash forever.
      await firebaseReady.timeout(const Duration(seconds: 12));
    } catch (e, st) {
      debugPrint('Firebase init failed/timed out: $e\n$st');
      // Fall through to signed-out; user can still reach Welcome / guest.
      if (!mounted) return;
      _revealDestination(_AuthState.signedOut);
      return;
    }

    try {
      final results = await Future.wait([
        _onboardingPrefs.isCompleted(),
        _kohaAuth.isLoggedIn(),
      ]);
      final onboardingDone = results[0];
      final hasKohaSession = results[1];
      final hasFirebaseSession = _firebaseAuth.currentUser != null;

      late final _AuthState sessionState;
      if (hasKohaSession && hasFirebaseSession) {
        sessionState = _AuthState.authenticated;
      } else {
        if (hasKohaSession || hasFirebaseSession) {
          await _kohaAuth.logout();
          await _firebaseAuth.signOut();
        }
        final isGuest = await _secureStorage.isGuestMode();
        sessionState = isGuest ? _AuthState.guest : _AuthState.signedOut;
      }

      const minHold = Duration(milliseconds: 900);
      final elapsed = DateTime.now().difference(started);
      if (elapsed < minHold) {
        await Future<void>.delayed(minHold - elapsed);
      }
      if (!mounted) return;

      if (!onboardingDone) {
        _pendingAfterOnboarding = sessionState;
        _revealDestination(_AuthState.onboarding);
        return;
      }

      _revealDestination(sessionState);
    } catch (e, st) {
      debugPrint('Session restore failed: $e\n$st');
      if (mounted) _revealDestination(_AuthState.signedOut);
    }
  }

  void _revealDestination(_AuthState next) {
    FlutterNativeSplash.remove();
    setState(() => _state = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _splashOpacity = 0);
      // Backup if AnimatedOpacity.onEnd doesn't fire.
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (mounted && _splashMounted) {
          setState(() => _splashMounted = false);
        }
      });
    });
  }

  void _onSplashFadeEnd() {
    if (_splashOpacity == 0 && _splashMounted && mounted) {
      setState(() => _splashMounted = false);
    }
  }

  Future<void> _finishOnboarding() async {
    await _onboardingPrefs.setCompleted();
    if (!mounted) return;
    setState(() {
      _state = _pendingAfterOnboarding ?? _AuthState.signedOut;
      _pendingAfterOnboarding = null;
    });
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

  /// Exposed via AuthScope as `onLogout`. Doubles as "exit guest mode" —
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
    final colors = useTheme(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_state == _AuthState.loading)
          ColoredBox(color: colors.background.primary)
        else
          _buildDestination(),
        if (_splashMounted)
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _splashOpacity,
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              onEnd: _onSplashFadeEnd,
              child: const SplashScreen(),
            ),
          ),
      ],
    );
  }

  Widget _buildDestination() {
    switch (_state) {
      case _AuthState.loading:
        return const SizedBox.shrink();
      case _AuthState.onboarding:
        return OnboardingScreen(onFinished: _finishOnboarding);
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
