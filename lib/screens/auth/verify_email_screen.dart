import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../navigation/routes.dart';
import '../../services/firebase_auth_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Step 2 of registration: the student has a temp Firebase account and a
/// verification email in their inbox. This screen waits for them to click
/// it, then re-checks `emailVerified` on demand (SDS §9.9's "student must
/// click the link before the form unlocks").
class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = FirebaseAuthService();
  bool _isChecking = false;
  bool _isResending = false;
  String? _statusMessage;
  bool _statusIsError = false;

  Future<void> _handleCheckVerified() async {
    setState(() {
      _isChecking = true;
      _statusMessage = null;
    });

    final verified = await _authService.checkEmailVerified();

    if (!mounted) return;

    if (verified) {
      Navigator.of(context).pushNamed(AuthRoutes.signupForm);
    } else {
      setState(() {
        _statusMessage = 'Not verified yet — check your inbox and tap the link, then try again.';
        _statusIsError = true;
      });
    }
    setState(() => _isChecking = false);
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _statusMessage = null;
    });
    try {
      await _authService.sendVerificationEmail();
      setState(() {
        _statusMessage = 'Verification email resent.';
        _statusIsError = false;
      });
    } catch (_) {
      setState(() {
        _statusMessage = 'Could not resend right now. Try again in a moment.';
        _statusIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.intents.info.light.bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(LucideIcons.mail_open, size: 32, color: colors.brand),
          ),
          const SizedBox(height: AppSpacing.lg),
          Heading(text: 'Check your email', level: 3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'We sent a verification link to ${widget.email}. Open it, then come back and tap the button below.',
            variant: 'bodyBase',
            tone: 'secondary',
            textAlign: TextAlign.center,
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppText(
              _statusMessage!,
              variant: 'bodySmall',
              tone: _statusIsError ? 'error' : 'brand',
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: "I've verified",
            onPressed: _isChecking ? null : _handleCheckVerified,
            isLoading: _isChecking,
          ),
          const SizedBox(height: AppSpacing.ms),
          AppButton(
            label: 'Resend email',
            variant: 'text',
            onPressed: _isResending ? null : _handleResend,
            isLoading: _isResending,
          ),
        ],
      ),
    );
  }
}