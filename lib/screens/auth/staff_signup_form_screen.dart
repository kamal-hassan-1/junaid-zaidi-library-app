import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../data/campuses.dart';
import '../../models/student_request.dart';
import '../../navigation/routes.dart';
import '../../services/crypto_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
// Same password policy as the Student form: at least 8 characters, with
// at least one letter and one digit.
final _passwordHasLetter = RegExp(r'[A-Za-z]');
final _passwordHasDigit = RegExp(r'\d');
final _fullNamePattern = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');

/// The lightweight Staff/Teacher registration screen (Updated
/// Authentication Workflow â€” role-aware registration). Reached from
/// RoleSelectionScreen when the "Staff" or "Teacher" card is tapped â€”
/// [role] carries which one so this single screen can serve both,
/// differing only by label text and the [StudentRequest.role] written
/// to Firestore.
///
/// Deliberately collects far less than SignupFormScreen: no
/// registration number, department, phone, or CNIC â€” none of those
/// apply to Staff/Teacher. Submitting still writes a single Pending
/// student_requests document with an encrypted password and waits on
/// the same librarian-approval flow; see StudentRequest.forOtherRole
/// and functions/index.js.
class StaffSignupFormScreen extends StatefulWidget {
  final String role;

  const StaffSignupFormScreen({super.key, required this.role});

  @override
  State<StaffSignupFormScreen> createState() => _StaffSignupFormScreenState();
}

class _StaffSignupFormScreenState extends State<StaffSignupFormScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _cryptoService = CryptoService();
  final _firestoreService = FirestoreService();

  String? _selectedCampus;

  String? _fullNameError;
  String? _campusError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _formError;

  bool _fullNameTouched = false;
  bool _campusTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;

  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(() {
      _fullNameTouched = true;
      _validateFullName();
    });
    _emailController.addListener(() {
      _emailTouched = true;
      _validateEmail();
    });
    _passwordController.addListener(() {
      _passwordTouched = true;
      _validatePassword();
      if (_confirmPasswordTouched) _validateConfirmPassword();
    });
    _confirmPasswordController.addListener(() {
      _confirmPasswordTouched = true;
      _validateConfirmPassword();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateFullName() {
    final name = _fullNameController.text.trim();
    String? error;
    if (name.isEmpty) {
      error = 'Enter your full name.';
    } else if (name.length < 5) {
      error = 'Full name must be at least 5 characters.';
    } else if (!_fullNamePattern.hasMatch(name)) {
      error = 'Only letters and spaces are allowed â€” no numbers or symbols.';
    }
    if (mounted) setState(() => _fullNameError = error);
    return error == null;
  }

  bool _validateCampus() {
    String? error;
    if (_selectedCampus == null || _selectedCampus!.isEmpty) {
      error = 'Select your campus.';
    }
    if (mounted) setState(() => _campusError = error);
    return error == null;
  }

  bool _validateEmail() {
    final email = _emailController.text.trim().toLowerCase();
    String? error;
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      error = 'Enter a valid email address.';
    } else if (!email.endsWith('@comsats.edu.pk')) {
      error = '${widget.role} accounts must use a @comsats.edu.pk email.';
    }
    if (mounted) setState(() => _emailError = error);
    return error == null;
  }

  bool _validatePassword() {
    final password = _passwordController.text;
    String? error;
    if (password.length < 8 ||
        !_passwordHasLetter.hasMatch(password) ||
        !_passwordHasDigit.hasMatch(password)) {
      error = 'At least 8 characters, with a mix of letters and numbers.';
    }
    if (mounted) setState(() => _passwordError = error);
    return error == null;
  }

  bool _validateConfirmPassword() {
    String? error;
    if (_confirmPasswordController.text != _passwordController.text) {
      error = 'Passwords do not match.';
    }
    if (mounted) setState(() => _confirmPasswordError = error);
    return error == null;
  }

  bool _validate() {
    setState(() => _formError = null);
    _fullNameTouched = true;
    _campusTouched = true;
    _emailTouched = true;
    _passwordTouched = true;
    _confirmPasswordTouched = true;

    final validations = [
      _validateFullName(),
      _validateCampus(),
      _validateEmail(),
      _validatePassword(),
      _validateConfirmPassword(),
    ];

    return !validations.contains(false);
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final encryptedPassword = _cryptoService.encryptPassword(_passwordController.text);

      final request = StudentRequest.forOtherRole(
        role: widget.role,
        fullName: _fullNameController.text.trim(),
        campus: _selectedCampus!,
        email: _emailController.text.trim().toLowerCase(),
        encryptedPassword: encryptedPassword,
      );
      await _firestoreService.submitStudentRequest(request);

      if (!mounted) return;
      setState(() => _isSubmitted = true);
    } catch (_) {
      setState(() =>
          _formError = 'Could not submit your request. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleBackToWelcome() {
    Navigator.of(context).popUntil((route) => route.settings.name == AuthRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _StaffSubmittedView(onDone: _handleBackToWelcome);
    }

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
                  const Icon(LucideIcons.arrow_left, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  AppText('Back', variant: 'bodyBase', tone: 'secondary'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Heading(text: 'Create your ${widget.role.toLowerCase()} account', level: 3),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Fill this in and a librarian will review your request before you can log in.',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppTextField(
              label: 'Full name',
              controller: _fullNameController,
              placeholder: 'e.g. Ayesha Khan',
              prefixIcon: LucideIcons.user,
              errorText: _fullNameTouched ? _fullNameError : null,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdownField(
              label: 'Campus',
              value: _selectedCampus,
              options: kComsatsCampuses,
              placeholder: 'Select your campus',
              prefixIcon: LucideIcons.map_pin,
              errorText: _campusTouched ? _campusError : null,
              onChanged: (value) {
                _campusTouched = true;
                setState(() => _selectedCampus = value);
                _validateCampus();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'COMSATS email',
              controller: _emailController,
              placeholder: 'you@comsats.edu.pk',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: LucideIcons.mail,
              errorText: _emailTouched ? _emailError : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Password',
              controller: _passwordController,
              placeholder: 'At least 8 characters, letters + numbers',
              obscureText: true,
              prefixIcon: LucideIcons.lock,
              errorText: _passwordTouched ? _passwordError : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Confirm password',
              controller: _confirmPasswordController,
              placeholder: 'Re-enter your password',
              obscureText: true,
              prefixIcon: LucideIcons.lock,
              errorText: _confirmPasswordTouched ? _confirmPasswordError : null,
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
/// Firestore. Kept inside this file, mirroring SignupFormScreen's
/// _SubmittedView, since it's a state of the same step, not a new
/// route.
class _StaffSubmittedView extends StatelessWidget {
  final VoidCallback onDone;

  const _StaffSubmittedView({required this.onDone});

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
            child: Icon(LucideIcons.circle_check, size: 36, color: colors.intents.success.light.fg),
          ),
          const SizedBox(height: AppSpacing.lg),
          Heading(text: 'Request submitted', level: 3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Your registration request has been submitted successfully. Please wait for administrator approval.',
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
