import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../navigation/routes.dart';
import '../../services/koha_auth_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// The real login (SDS §9.9) — goes straight to Koha's
/// POST /api/v1/auth/password, never through Firebase. Firebase's only
/// role in this app ends at email verification during sign-up.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _kohaAuth = KohaAuthService();

  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() => _formError = null);

    if (username.isEmpty || password.isEmpty) {
      setState(() => _formError = 'Enter your username and password.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _kohaAuth.login(username: username, password: password);
      if (!mounted) return;
      widget.onLoginSuccess();
    } on KohaAuthException catch (e) {
      setState(() => _formError = e.message);
    } catch (_) {
      setState(() => _formError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ScreenContainer(
        scroll: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(LucideIcons.arrow_left, size: 20, color: colors.icon),
                  const SizedBox(width: AppSpacing.xs),
                  AppText('Back', variant: 'bodyBase', tone: 'secondary'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.intents.info.light.bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.lock, size: 28, color: colors.brand),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText('Log in', variant: 'h3', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Use the library username and password given to you after approval.',
              variant: 'bodyBase',
              tone: 'secondary',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Username',
                    controller: _usernameController,
                    placeholder: 'Your library username',
                    prefixIcon: LucideIcons.user,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    placeholder: 'Your library password',
                    obscureText: true,
                    prefixIcon: LucideIcons.lock,
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppText(_formError!, variant: 'bodySmall', tone: 'error'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Log in',
              onPressed: _isSubmitting ? null : _handleLogin,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: AppSpacing.ms),
            AppButton(
              label: "Don't have an account? Create one",
              variant: 'text',
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pushNamed(AuthRoutes.signupEmail),
            ),
          ],
        ),
      ),
    );
  }
}