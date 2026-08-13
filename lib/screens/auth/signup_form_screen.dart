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

final _cnicPattern = RegExp(r'^\d{5}-\d{7}-\d$');
final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
final _passwordHasLetter = RegExp(r'[A-Za-z]');
final _passwordHasDigit = RegExp(r'\d');

final _fullNamePattern = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$');

final _regNumberPattern = RegExp(r'^[A-Z]{2}\d{2}-[A-Z]{2,5}-\d{3}$');

final _phonePattern = RegExp(r'^03\d{2}-\d{7}$');

const Map<String, String> _departmentCodeMap = {
  // ---- Computer Science --------------------------------------------
  // These are all programs offered BY the single Computer Science
  // department, not separate departments â€” so they all resolve to
  // the same department name.
  'BCS': 'Department of Computer Science', // BS Computer Science
  'CS': 'Department of Computer Science',
  'BCT': 'Department of Computer Science', // BS Computer Technology
  'BSE': 'Department of Computer Science', // BS Software Engineering
  'SE': 'Department of Computer Science',
  'BAI': 'Department of Computer Science', // BS Artificial Intelligence
  'AI': 'Department of Computer Science',
  'BDS': 'Department of Computer Science', // BS Data Science
  'DS': 'Department of Computer Science',

  // ---- Information Technology --------------------------------------
  'IT': 'Department of Information Technology',
  'BIT': 'Department of Information Technology',

  // ---- Cyber Security ----------------------------------------------
  'CYS': 'Department of Cyber Security',

  // ---- Electrical Engineering --------------------------------------
  'EE': 'Department of Electrical Engineering',
  'BEE': 'Department of Electrical Engineering',
  'ELE': 'Department of Electrical Engineering',

  // ---- Civil Engineering -------------------------------------------
  'CE': 'Department of Civil Engineering',
  'BCE': 'Department of Civil Engineering',

  // ---- Mechanical Engineering --------------------------------------
  'ME': 'Department of Mechanical Engineering',
  'BME': 'Department of Mechanical Engineering',

  // ---- Management Sciences (business, NOT Computer Science) --------
  'BBA': 'Department of Management Sciences',
  'MBA': 'Department of Management Sciences',

  // ---- Accounting & Finance ----------------------------------------
  'ACC': 'Department of Accounting & Finance',
  'ACF': 'Department of Accounting & Finance',

  // ---- Economics ---------------------------------------------------
  'ECO': 'Department of Economics',

  // ---- English -----------------------------------------------------
  'ENG': 'Department of English',

  // ---- Mathematics -------------------------------------------------
  'MATH': 'Department of Mathematics',

  // ---- Statistics --------------------------------------------------
  'STAT': 'Department of Statistics',

  // ---- Psychology --------------------------------------------------
  'PSY': 'Department of Psychology',

  // ---- Biosciences -------------------------------------------------
  'BIO': 'Department of Biosciences',

  // ---- Biotechnology -----------------------------------------------
  'BT': 'Department of Biotechnology',

  // ---- Physics -----------------------------------------------------
  'PHY': 'Department of Physics',

  // ---- Chemistry ---------------------------------------------------
  'CHE': 'Department of Chemistry',

  // ---- Architecture ------------------------------------------------
  'ARCH': 'Department of Architecture',

  // ---- Law ---------------------------------------------------------
  'LAW': 'Department of Law',

  // ---- Environmental Sciences --------------------------------------
  'ENV': 'Department of Environmental Sciences',

  // ---- Meteorology -------------------------------------------------
  'MET': 'Department of Meteorology',

  // ---- Pharmacy ----------------------------------------------------
  'PHM': 'Department of Pharmacy',
};

/// All COMSATS department names available for manual selection in the
/// Department dropdown â€” derived from [_departmentCodeMap] so the
/// dropdown's option list and the auto-fill map can never drift apart.
/// Deduped (several codes map to the same department, e.g. BCS/CS) and
/// sorted alphabetically for a predictable dropdown order.
final List<String> kComsatsDepartments = _departmentCodeMap.values.toSet().toList()..sort();

/// The full Student registration screen (Updated Authentication
/// Workflow â€” role-aware registration: this is the [RegistrationRole.
/// student] path; Staff/Teacher go through StaffSignupFormScreen
/// instead). Submitting writes a single Pending student_requests
/// document with an encrypted password â€” no Firebase account and no
/// Koha patron exist until a librarian approves it (see
/// functions/index.js).
///
/// Every field validates live via controller listeners (see
/// _attachLiveValidation in initState) in addition to a full re-check on
/// submit, so errors clear/appear as the student types instead of only
/// on submit.
class SignupFormScreen extends StatefulWidget {
  const SignupFormScreen({super.key});

  @override
  State<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends State<SignupFormScreen> {
  final _fullNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController(text: '03');
  final _cnicController = TextEditingController();

  final _cryptoService = CryptoService();
  final _firestoreService = FirestoreService();

  String? _selectedCampus;
  String? _selectedDepartment;

  String? _fullNameError;
  String? _regNumberError;
  String? _departmentError;
  String? _campusError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _phoneError;
  String? _cnicError;
  String? _formError;

  bool _departmentEditedByUser = false;

  // Only start showing an error for a field once the student has
  // interacted with it â€” otherwise every field would show red before
  // they've typed a single character.
  bool _fullNameTouched = false;
  bool _regNumberTouched = false;
  bool _departmentTouched = false;
  bool _campusTouched = false;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;
  bool _phoneTouched = false;
  bool _cnicTouched = false;

  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(() {
      _fullNameTouched = true;
      _validateFullName();
    });
    _regNumberController.addListener(() {
      _regNumberTouched = true;
      _validateRegNumber();
      _maybeAutoFillDepartment();
    });
    
    _emailController.addListener(() {
      _emailTouched = true;
      _validateEmail();
    });
    _passwordController.addListener(() {
      _passwordTouched = true;
      _validatePassword();
      // Re-check confirm password too, since it depends on this value.
      if (_confirmPasswordTouched) _validateConfirmPassword();
    });
    _confirmPasswordController.addListener(() {
      _confirmPasswordTouched = true;
      _validateConfirmPassword();
    });
    _phoneController.addListener(() {
      _phoneTouched = true;
      _validatePhone();
    });
    _cnicController.addListener(() {
      _cnicTouched = true;
      _validateCnic();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _regNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    super.dispose();
  }

  // ---- Per-field live validators -----------------------------------
  // Each returns true/false AND updates the matching error string, so
  // they can be reused both by the listeners above (live, per-keystroke)
  // and by _validate() (full check on submit).

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

  bool _validateRegNumber() {
    final reg = _regNumberController.text.trim().toUpperCase();
    String? error;
    if (reg.isEmpty) {
      error = 'Enter your registration number.';
    } else if (!_regNumberPattern.hasMatch(reg)) {
      error = 'Use the format FA23-BCS-050 (season, year, department, roll no).';
    }
    if (mounted) setState(() => _regNumberError = error);
    return error == null;
  }

  bool _validateDepartment() {
    String? error;
    if (_selectedDepartment == null || _selectedDepartment!.isEmpty) {
      error = 'Select your department.';
    }
    if (mounted) setState(() => _departmentError = error);
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
    } else if (!email.endsWith('@isbstudent.comsats.edu.pk')) {
      error = 'Use your COMSATS Outlook email (must end with @isbstudent.comsats.edu.pk).';
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

  bool _validatePhone() {
    final phone = _phoneController.text.trim();
    String? error;
    if (phone.isEmpty || phone == '03') {
      error = 'Enter your phone number.';
    } else if (!_phonePattern.hasMatch(phone)) {
      error = 'Use the format 03XX-XXXXXXX (11 digits, starting with 03).';
    }
    if (mounted) setState(() => _phoneError = error);
    return error == null;
  }

  bool _validateCnic() {
    String? error;
    if (!_cnicPattern.hasMatch(_cnicController.text.trim())) {
      error = 'Enter your CNIC as xxxxx-xxxxxxx-x.';
    }
    if (mounted) setState(() => _cnicError = error);
    return error == null;
  }

  /// Reads the department code out of a (possibly partial) registration
  /// number and auto-selects the matching entry in [kComsatsDepartments]
  /// via [_departmentCodeMap] â€” but only while the student hasn't picked
  /// a department themselves from the dropdown.
  void _maybeAutoFillDepartment() {
    if (_departmentEditedByUser) return;

    final reg = _regNumberController.text.trim().toUpperCase();
    // Registration number so far looks like SS##-CODE(-###)?
    final match = RegExp(r'^[A-Z]{2}\d{2}-([A-Z]{2,5})').firstMatch(reg);
    if (match == null) return;

    final code = match.group(1)!;
    final department = _departmentCodeMap[code];
    if (department != null && _selectedDepartment != department) {
      setState(() => _selectedDepartment = department);
      if (_departmentTouched) _validateDepartment();
    }
  }

  bool _validate() {
    setState(() => _formError = null);
    _fullNameTouched = true;
    _regNumberTouched = true;
    _departmentTouched = true;
    _campusTouched = true;
    _emailTouched = true;
    _passwordTouched = true;
    _confirmPasswordTouched = true;
    _phoneTouched = true;
    _cnicTouched = true;

    final validations = [
      _validateFullName(),
      _validateRegNumber(),
      _validateDepartment(),
      _validateCampus(),
      _validateEmail(),
      _validatePassword(),
      _validateConfirmPassword(),
      _validatePhone(),
      _validateCnic(),
    ];

    return !validations.contains(false);
  }

  Future<void> _handleSubmit() async {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final encryptedPassword = _cryptoService.encryptPassword(_passwordController.text);

      final request = StudentRequest(
        role: RegistrationRole.student,
        campus: _selectedCampus!,
        fullName: _fullNameController.text.trim(),
        registrationNumber: _regNumberController.text.trim().toUpperCase(),
        department: _selectedDepartment!,
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        cnic: _cnicController.text.trim(),
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
            Heading(text: 'Create your account', level: 3),
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
              placeholder: 'e.g. Muaaz Tasawar',
              prefixIcon: LucideIcons.user,
              errorText: _fullNameTouched ? _fullNameError : null,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Registration number',
              controller: _regNumberController,
              placeholder: 'e.g. FA23-BCS-050',
              prefixIcon: LucideIcons.id_card,
              errorText: _regNumberTouched ? _regNumberError : null,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
                LengthLimitingTextInputFormatter(13),
                _UpperCaseFormatter(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdownField(
              label: 'Department',
              value: _selectedDepartment,
              options: kComsatsDepartments,
              placeholder: 'Auto-filled from registration number, or select manually',
              prefixIcon: LucideIcons.graduation_cap,
              errorText: _departmentTouched ? _departmentError : null,
              onChanged: (value) {
                _departmentTouched = true;
                _departmentEditedByUser = true;
                setState(() => _selectedDepartment = value);
                _validateDepartment();
              },
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
              label: 'COMSATS Outlook email',
              controller: _emailController,
              placeholder: 'you@isbstudent.comsats.edu.pk',
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
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Phone number',
              controller: _phoneController,
              placeholder: '03XX-XXXXXXX',
              keyboardType: TextInputType.phone,
              prefixIcon: LucideIcons.phone,
              errorText: _phoneTouched ? _phoneError : null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
                _PhoneDashFormatter(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'CNIC',
              controller: _cnicController,
              placeholder: 'xxxxx-xxxxxxx-x',
              keyboardType: TextInputType.number,
              prefixIcon: LucideIcons.file_text,
              errorText: _cnicTouched ? _cnicError : null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(13),
                _CnicDashFormatter(),
              ],
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

/// Forces every character typed into the registration-number field to
/// uppercase as it's typed, so "fa23-bcs-050" displays (and validates)
/// the same as "FA23-BCS-050".
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

/// Auto-inserts the two CNIC dashes as the student types, so the field
/// always displays as xxxxx-xxxxxxx-x. Combined with
/// FilteringTextInputFormatter.digitsOnly (upstream in the formatter
/// chain), this only ever sees raw digits as input.
class _CnicDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 4 || i == 11) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Auto-inserts the single dash for a Pakistani mobile number as the
/// student types, so the field always displays as 03XX-XXXXXXX (11
/// digits total, dash after the 4th). Combined with
/// FilteringTextInputFormatter.digitsOnly upstream, this only ever sees
/// raw digits.
class _PhoneDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final digits = newValue.text;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 3) buffer.write('-');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
