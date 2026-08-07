import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/student_request.dart';
import '../../navigation/routes.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Shown after "Create Account" on WelcomeScreen, before either signup
/// form (Updated Authentication Workflow â€” role-aware registration).
/// Mirrors the Student / Staff / Teacher split already used as a
/// display-only toggle on email_login_screen.dart, but as a dedicated
/// screen rather than inline chips since picking wrong here sends the
/// student down an entirely different form, not just a different email
/// domain check.
///
/// Navigates with its own `context` (pushNamed calls below), same as
/// every other screen in this flow (see SignupFormScreen's Back
/// button) â€” deliberately NOT via callbacks from AuthGate, since
/// AuthGate's own State.context sits above the nested auth Navigator
/// that owns these routes; using it there resolves to the app's root
/// Navigator instead and the push silently fails to find a generator.
///
/// Student goes on to the full SignupFormScreen (registration number,
/// department, CNIC, the works). Staff and Teacher both go to the
/// lighter StaffSignupFormScreen â€” name, COMSATS email, campus, and
/// password only â€” since neither has a registration number or a
/// CNIC-on-file requirement. Every path still ends in the same Pending
/// student_requests document awaiting librarian approval; only the
/// value of [StudentRequest.role] differs.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
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
          Heading(text: 'Who are you registering as?', level: 3),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'This decides which registration form you fill in.',
            variant: 'bodyBase',
            tone: 'secondary',
          ),
          const SizedBox(height: AppSpacing.xl),
          _RoleCard(
            icon: LucideIcons.graduation_cap,
            title: 'Student',
            subtitle: 'Registration number, department, CNIC and more.',
            onTap: () => Navigator.of(context).pushNamed(AuthRoutes.signupForm),
          ),
          const SizedBox(height: AppSpacing.md),
          _RoleCard(
            icon: LucideIcons.briefcase,
            title: 'Staff',
            subtitle: 'Just your name, COMSATS email, and password.',
            onTap: () => Navigator.of(context).pushNamed(
              AuthRoutes.staffSignupForm,
              arguments: RegistrationRole.staff,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _RoleCard(
            icon: LucideIcons.book_open,
            title: 'Teacher',
            subtitle: 'Just your name, COMSATS email, and password.',
            onTap: () => Navigator.of(context).pushNamed(
              AuthRoutes.staffSignupForm,
              arguments: RegistrationRole.teacher,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.background.secondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
          boxShadow: shadow.boxShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.brand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 22, color: colors.brand),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    variant: 'bodyBase',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  AppText(subtitle, variant: 'bodySmall', tone: 'secondary'),
                ],
              ),
            ),
            Icon(LucideIcons.chevron_right, size: 18, color: colors.icon),
          ],
        ),
      ),
    );
  }
}
