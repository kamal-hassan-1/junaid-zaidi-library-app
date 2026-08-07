import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/koha_auth_service.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Registration number: SS##-DEPT-### e.g. FA23-BCS-050 — same format
/// enforced on the signup form.
final _regNumberPattern = RegExp(r'^[A-Z]{2}\d{2}-[A-Z]{2,5}-\d{3}$');
final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

/// Who is logging in. Only affects which fields show and which email
/// domain is required — see the class doc below for why it does NOT yet
/// change what actually gets sent to Firebase/Koha.
enum _LoginRole { student, staff, teacher }

extension on _LoginRole {
  String get label {
    switch (this) {
      case _LoginRole.student:
        return 'Student';
      case _LoginRole.staff:
        return 'Staff';
      case _LoginRole.teacher:
        return 'Teacher';
    }
  }
}

/// The single real login screen (Updated Authentication Workflow, Phase
/// 3 / Steps 12-16). Sends the SAME email + password to both Firebase
/// Auth and Koha's /api/v1/auth/password — both must succeed, matching
/// the doc's dual-login requirement. Koha's userid is set to the
/// student's email at patron-creation time (see functions/index.js), so
/// one email+password pair genuinely works for both systems; there's no
/// separate "username" concept anymore, which is why the old
/// login_screen.dart (Koha-only, username-based) was removed rather than
/// kept as a second screen.
///
/// Role selector (Student / Staff / Teacher): this only changes which
/// fields are shown and which validation rules apply on-device —
/// Student shows a Registration number field and requires a
/// @isbstudent.comsats.edu.pk email; Staff/Teacher hide that field and
/// require a plain @comsats.edu.pk email instead. The actual
/// authentication call below is still unchanged: Firebase + Koha, and
/// both only know about approved students (see functions/index.js and
/// the student_requests-based approval flow). Selecting Staff or
/// Teacher will validate correctly but the sign-in call itself will
/// fail for anyone who isn't already a student account, because there
/// is no staff/teacher account type on the backend yet. Wire that up
/// (a role field on the account + a Koha patron category for
/// staff/faculty) before this selector is more than a form toggle.
class EmailLoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const EmailLoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _firebaseAuth = FirebaseAuthService();
  final _kohaAuth = KohaAuthService();
  final _firestoreService = FirestoreService();

  _LoginRole _role = _LoginRole.student;

  String? _emailError;
  String? _regNumberError;
  String? _formError;
  String? _infoMessage;
  bool _emailTouched = false;
  bool _regNumberTouched = false;
  bool _isSubmitting = false;
  bool _isSendingReset = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      _emailTouched = true;
      _validateEmail();
    });
    _regNumberController.addListener(() {
      _regNumberTouched = true;
      _validateRegNumber();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNumberController.dispose();
    super.dispose();
  }

  String get _requiredDomain =>
      _role == _LoginRole.student ? '@isbstudent.comsats.edu.pk' : '@comsats.edu.pk';

  bool _validateEmail() {
    final email = _emailController.text.trim().toLowerCase();
    String? error;
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      error = 'Enter a valid email address.';
    } else if (!email.endsWith(_requiredDomain)) {
      error = _role == _LoginRole.student
          ? 'Students must log in with a $_requiredDomain email.'
          : '${_role.label} accounts must log in with a $_requiredDomain email.';
    }
    if (mounted) setState(() => _emailError = error);
    return error == null;
  }

  bool _validateRegNumber() {
    if (_role != _LoginRole.student) {
      if (mounted) setState(() => _regNumberError = null);
      return true;
    }
    final reg = _regNumberController.text.trim().toUpperCase();
    String? error;
    if (reg.isEmpty) {
      error = 'Enter your registration number.';
    } else if (!_regNumberPattern.hasMatch(reg)) {
      error = 'Use the format FA23-BCS-050.';
    }
    if (mounted) setState(() => _regNumberError = error);
    return error == null;
  }

  void _selectRole(_LoginRole role) {
    if (role == _role) return;
    setState(() {
      _role = role;
      _formError = null;
      _infoMessage = null;
    });
    // Domain requirement and (for student) registration-number
    // requirement both depend on the role, so re-check whatever the
    // user has already touched.
    if (_emailTouched) _validateEmail();
    if (_regNumberTouched) _validateRegNumber();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() {
      _formError = null;
      _infoMessage = null;
      _emailTouched = true;
      _regNumberTouched = true;
    });

    final emailOk = _validateEmail();
    final regNumberOk = _validateRegNumber();
    if (password.isEmpty) {
      setState(() => _formError = 'Enter your password.');
      return;
    }
    if (!emailOk || !regNumberOk) return;

    setState(() => _isSubmitting = true);
    try {
      // Step 1 of 2: Firebase. If this fails, nothing has been created
      // anywhere, so there's nothing to roll back — just report why.
      try {
        await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (_) {
        final message = await _firebaseAuth.describeSignInFailure(email, _firestoreService);
        setState(() => _formError = message);
        return;
      }

      // Step 2 of 2: Koha. Both must succeed (Step 15) — if Koha
      // rejects credentials that Firebase just accepted, sign back out
      // of Firebase so the app never sits in a half-authenticated
      // state where one side thinks the student is in and the other
      // doesn't.
      try {
        await _kohaAuth.login(username: email, password: password);
      } on KohaAuthException catch (e) {
        await _firebaseAuth.signOut();
        setState(() => _formError = e.message);
        return;
      } catch (_) {
        await _firebaseAuth.signOut();
        setState(() =>
            _formError = 'Could not verify your library account. Please try again.');
        return;
      }

      if (!mounted) return;
      widget.onLoginSuccess();
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
    const neutralMessage =
        'If that email has an approved account, a password reset link was sent. '
        'Note: this only resets your Firebase sign-in — for your library (Koha) '
        'password too, use "Request password change" from your profile instead.';
    try {
      await _firebaseAuth.sendPasswordResetEmail(email);
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
            AppText('Log in', variant: 'h3', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              'Use the email and password you signed up with — only works once your request is approved.',
              variant: 'bodyBase',
              tone: 'secondary',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            _RoleSelector(role: _role, onChanged: _selectRole),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_role == _LoginRole.student) ...[
                    AppTextField(
                      label: 'Registration number',
                      controller: _regNumberController,
                      placeholder: 'e.g. FA23-BCS-050',
                      prefixIcon: LucideIcons.id_card,
                      errorText: _regNumberTouched ? _regNumberError : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    placeholder: _role == _LoginRole.student
                        ? 'you@isbstudent.comsats.edu.pk'
                        : 'you@comsats.edu.pk',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: LucideIcons.mail,
                    errorText: _emailTouched ? _emailError : null,
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

/// Three-way Student / Staff / Teacher chip selector shown above the
/// login card. Deliberately a plain Row of tappable chips rather than a
/// new shared widget — this is the only screen that needs a role picker
/// right now, so it isn't promoted into widgets/ui.dart.
class _RoleSelector extends StatelessWidget {
  final _LoginRole role;
  final ValueChanged<_LoginRole> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return Row(
      children: _LoginRole.values.map((option) {
        final isSelected = option == role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option == _LoginRole.values.last ? 0 : AppSpacing.sm,
            ),
            child: GestureDetector(
              onTap: () => onChanged(option),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? colors.brand : colors.background.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? colors.brand : colors.border,
                    width: 1,
                  ),
                ),
                child: AppText(
                  option.label,
                  variant: 'bodySmall',
                  style: TextStyle(
                    color: isSelected ? colors.text.onBrand : colors.text.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
