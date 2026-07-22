import 'package:flutter/material.dart';

import '../../navigation/auth_scope.dart';
import '../../navigation/routes.dart';
import '../../services/koha_auth_service.dart';
import '../../theme/semantic/light.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';
import '../root_shell.dart';
import 'login_screen.dart';
import 'signup_email_screen.dart';
import 'signup_form_screen.dart';
import 'verify_email_screen.dart';
import 'welcome_screen.dart';

/// Decides between the auth flow and the app itself, based on whether a
/// Koha session exists in secure storage (SDS Â§9.9 - Koha owns the real
/// session, Firebase never does). Session state is held as real State
/// (`_hasSession`) so both login (Phase 5) and logout (this change) can
/// flip the app over live, with no restart needed either direction.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _kohaAuth = KohaAuthService();

  /// null = still checking on boot, true/false = known session state.
  bool? _hasSession;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasSession = await _kohaAuth.isLoggedIn();
    if (mounted) setState(() => _hasSession = hasSession);
  }

  /// Passed down to LoginScreen. Flips the gate over to RootShell the
  /// moment Koha login succeeds.
  void _handleAuthenticated() {
    setState(() => _hasSession = true);
  }

  /// Exposed to RootShell's whole subtree via AuthScope. Clears the
  /// stored Koha token and flips the gate back to the signed-out flow.
  Future<void> _handleLogout() async {
    await _kohaAuth.logout();
    if (mounted) setState(() => _hasSession = false);
  }

  Route<dynamic> _onGenerateAuthRoute(RouteSettings settings) {
    late final Widget page;
    switch (settings.name) {
      case AuthRoutes.welcome:
        page = const WelcomeScreen();
      case AuthRoutes.login:
        page = LoginScreen(onLoginSuccess: _handleAuthenticated);
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
    if (_hasSession == null) {
      return const _AuthLoadingScreen();
    }

    if (_hasSession!) {
      return AuthScope(onLogout: _handleLogout, child: const RootShell());
    }

    return Navigator(
      initialRoute: AuthRoutes.welcome,
      onGenerateRoute: _onGenerateAuthRoute,
    );
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