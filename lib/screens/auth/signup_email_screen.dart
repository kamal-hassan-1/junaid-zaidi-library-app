import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../navigation/routes.dart';
import '../../services/firebase_auth_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Step 1 of registration: collects the email/password used only to prove
/// the student controls their COMSATS email (SDS §9.9). This account is
/// temporary — it exists purely to unlock the verification email, and
/// gets discarded (signed out) once the request is submitted in Phase 4.
class SignupEmailScreen extends StatefulWidget {
  const SignupEmailScreen({super.key});

  @override
  State<SignupEmailScreen> createState() => _SignupEmailScreenState();
}

class _SignupEmailScreenState extends State<SignupEmailScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();

  String? _emailError;
  String? _passwordError;
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _formError = null;
    });

    var isValid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address.');
      isValid = false;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      isValid = false;
    }
    return isValid;
  }

  Future<void> _handleContinue() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _authService.createTempAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _authService.sendVerificationEmail();

      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AuthRoutes.verifyEmail,
        arguments: _emailController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _emailError = 'An account already exists for this email.';
            break;
          case 'invalid-email':
            _emailError = 'That email address looks invalid.';
            break;
          case 'weak-password':
            _passwordError = 'Choose a stronger password.';
            break;
          default:
            _formError = e.message ?? 'Something went wrong. Please try again.';
        }
      });
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
                  color: colors.intents.success.light.bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.user_plus, size: 28, color: colors.intents.success.light.fg),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText('Create your account', variant: 'h3', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Use your COMSATS email — we\'ll send a verification link before you can register.',
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
                    label: 'Email',
                    controller: _emailController,
                    placeholder: 'you@cuiatd.edu.pk',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: LucideIcons.mail,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    placeholder: 'At least 6 characters',
                    obscureText: true,
                    prefixIcon: LucideIcons.lock,
                    errorText: _passwordError,
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
              label: 'Continue',
              onPressed: _isSubmitting ? null : _handleContinue,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}