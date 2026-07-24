import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Login using the email/password account created during signup — valid
/// only once a librarian has set the matching student_requests document's
/// status to Approved (see FirebaseAuthService.signInWithEmailAndPasswordApproved).
/// Separate from LoginScreen (Koha) and the Microsoft path (Phase 7) —
/// three distinct ways into the app, all recognized by AuthGate.
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _formError = null);

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
          ],
        ),
      ),
    );
  }
}