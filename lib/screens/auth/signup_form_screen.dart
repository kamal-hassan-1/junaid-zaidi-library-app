import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/student_request.dart';
import '../../navigation/routes.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Step 3 of registration: the student's Firebase email is now verified,
/// so this form writes a `student_requests` document (SDS �6.3) for a
/// librarian to review. Once the write succeeds, the temp Firebase
/// account is signed out � per SDS �9.9, Firebase's job ends here, it
/// never becomes the real session.
class SignupFormScreen extends StatefulWidget {
  const SignupFormScreen({super.key});

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  final _fullNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _phoneController = TextEditingController();

  final _authService = FirebaseAuthService();
  final _firestoreService = FirestoreService();

  String? _fullNameError;
  String? _regNumberError;
  String? _departmentError;
  String? _phoneError;
  String? _formError;

  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _regNumberController.dispose();
    _departmentController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _fullNameError = null;
      _regNumberError = null;
      _departmentError = null;
      _phoneError = null;
      _formError = null;
    });

    var isValid = true;
    if (_fullNameController.text.trim().isEmpty) {
      setState(() => _fullNameError = 'Enter your full name.');
      isValid = false;
    }
    if (_regNumberController.text.trim().isEmpty) {
      setState(() => _regNumberError = 'Enter your registration number.');
      isValid = false;
    }
    if (_departmentController.text.trim().isEmpty) {
      setState(() => _departmentError = 'Enter your department.');
      isValid = false;
    }
    if (_phoneController.text.trim().length < 7) {
      setState(() => _phoneError = 'Enter a valid phone number.');
      isValid = false;
    }
    return isValid;
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    final user = _authService.currentUser;
    final email = user?.email;
    if (email == null || !_authService.isEmailVerified) {
      setState(() => _formError =
      'Your email session expired — go back and verify your email again.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // user.reload() (back on the verify screen) updates the client-side
      // User object, but the cached ID token's email_verified claim isn't
      // refreshed by that alone — Firestore reads the token's claim, not
      // the client-side flag, so force a fresh token before writing or
      // firestore.rules rejects with permission-denied.
      await user!.getIdToken(true);
      final request = StudentRequest(
        fullName: _fullNameController.text.trim(),
        registrationNumber: _regNumberController.text.trim(),
        department: _departmentController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
      );
      await _firestoreService.submitStudentRequest(request);
      await _authService.signOut();

      if (!mounted) return;
      setState(() => _isSubmitted = true);
    }
  catch (e) {
    debugPrint('Submit request failed: $e');
    setState(() =>
    _formError =
    'Could not submit your request. Check your connection and try again.');
  }finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleBackToWelcome() {
    Navigator.of(context).popUntil((route) => route.settings.name == AuthRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _SubmittedView(onDone: _handleBackToWelcome);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ScreenContainer(
        scroll: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            Heading(text: 'Registration details', level: 3),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Your email is verified. Fill this in and a librarian will review your request.',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Full name',
              controller: _fullNameController,
              placeholder: 'e.g. Muaaz Tasawar',
              prefixIcon: LucideIcons.user,
              errorText: _fullNameError,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Registration number',
              controller: _regNumberController,
              placeholder: 'e.g. FA23-BCS-123',
              prefixIcon: LucideIcons.id_card,
              errorText: _regNumberError,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Department',
              controller: _departmentController,
              placeholder: 'e.g. Department of Computer Science',
              prefixIcon: LucideIcons.graduation_cap,
              errorText: _departmentError,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Phone number',
              controller: _phoneController,
              placeholder: 'e.g. 03001234567',
              keyboardType: TextInputType.phone,
              prefixIcon: LucideIcons.phone,
              errorText: _phoneError,
            ),
            if (_formError != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppText(_formError!, variant: 'bodySmall', tone: 'error'),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Submit request',
              onPressed: _isSubmitting ? null : _handleSubmit,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown in place of the form once the request has been written to
/// Firestore. Kept inside this file rather than a separate screen since
/// it's a state of the same step, not a new route.
class _SubmittedView extends StatelessWidget {
  final VoidCallback onDone;

  const _SubmittedView({required this.onDone});

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
              color: colors.intents.success.light.bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(LucideIcons.circle_check,
                size: 36, color: colors.intents.success.light.fg),
          ),
          const SizedBox(height: AppSpacing.lg),
          Heading(text: 'Request submitted', level: 3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'A librarian will review your details. You\'ll be able to log in once your account is approved.',
            variant: 'bodyBase',
            tone: 'secondary',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Back to start', onPressed: onDone),
        ],
      ),
    );
  }
}
