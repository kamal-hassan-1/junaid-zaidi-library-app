import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

class EmailLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const EmailLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  String? _formError;
  String? _infoMessage;
  bool _isSubmitting = false;
  bool _isSendingReset = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() {
      _formError = null;
      _infoMessage = null;
    });

    if (email.isEmpty || password.isEmpty) {
      setState(() => _formError = 'Enter your email and password.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authService.signInWithEmailAndPasswordApproved(
        email: email,
        password: password,
        firestoreService: _firestoreService,
      );
      if (!mounted) return;
      widget.onLoginSuccess();
    } on StateError catch (e) {
      setState(() => _formError = e.message);
    } catch (_) {
      setState(() => _formError = 'Incorrect email or password.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();

    setState(() {
      _formError = null;
      _infoMessage = null;
    });

    if (email.isEmpty) {
      setState(() => _formError = 'Enter your email above first, then tap "Forgot password?".');
      return;
    }

    setState(() => _isSendingReset = true);
    const neutralMessage = 'If that email has an account, a password reset link was sent.';
    try {
      await _authService.sendPasswordResetEmail(email);
      setState(() => _infoMessage = neutralMessage);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        setState(() => _infoMessage = neutralMessage);
      } else {
        setState(() => _formError = 'Could not send reset email. Try again in a moment.');
      }
    } catch (_) {
      setState(() => _formError = 'Could not send reset email. Try again in a moment.');
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
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
                child: Icon(LucideIcons.mail, size: 28, color: colors.brand),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppText('Log in with email', variant: 'h3', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Use the email and password you signed up with — only works once your request is approved.',
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
                    placeholder: 'you@isbstudent.comsats.edu.pk',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: LucideIcons.mail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Password',
                    controller: _passwordController,
                    placeholder: 'Your account password',
                    obscureText: true,
                    prefixIcon: LucideIcons.lock,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Forgot password?',
                      variant: 'text',
                      fullWidth: false,
                      isLoading: _isSendingReset,
                      onPressed: _isSendingReset ? null : _handleForgotPassword,
                    ),
                  ),
                  if (_formError != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(_formError!, variant: 'bodySmall', tone: 'error'),
                  ],
                  if (_infoMessage != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(_infoMessage!, variant: 'bodySmall', tone: 'brand'),
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
          ],
        ),
      ),
    );
  }
}