import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../models/profile_data.dart';
import '../../navigation/auth_scope.dart';
import '../../services/profile_loader.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

Widget _groupedList(SemanticColors colors, List<Widget> rows) {
  final shadow = cardShadowDecoration(colors);
  return Container(
    decoration: BoxDecoration(
      color: colors.background.secondary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: shadow.border,
      boxShadow: shadow.boxShadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: rows),
  );
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileLoader = ProfileLoader();

  ProfileData? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileLoader.load();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final isGuest = AuthScope.of(context).isGuest;

    if (isGuest) {
      return ScreenContainer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.intents.info.light.bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(LucideIcons.user, size: 32, color: colors.brand),
              ),
              const SizedBox(height: AppSpacing.lg),
              Heading(level: 4, text: "You're browsing as a guest", textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                'Sign up or log in to see your profile and borrow history.',
                variant: 'bodyBase',
                tone: 'secondary',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Sign Up / Sign In',
                onPressed: () => AuthScope.of(context).onLogout(),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _profile == null) {
      return ScreenContainer(
        child: Center(child: CircularProgressIndicator(color: colors.brand)),
      );
    }

    final profile = _profile ??
        const ProfileData(fullName: 'Profile unavailable', registrationNumber: '', isLimited: true);

    return ScreenContainer(
      scroll: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppAvatar(name: profile.fullName, size: 'large'),
                const SizedBox(height: AppSpacing.sm),
                Heading(level: 4, text: profile.fullName, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  profile.registrationNumber,
                  variant: 'bodyBase',
                  tone: 'secondary',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (profile.isLimited)
            _groupedList(colors, [
              ListRow(
                icon: LucideIcons.info,
                label: 'Full profile not available',
                secondaryLabel: 'Only shown for accounts created via Sign Up',
                showChevron: false,
                showDivider: false,
              ),
            ])
          else
            _groupedList(colors, [
              ListRow(
                icon: LucideIcons.graduation_cap,
                label: 'Department',
                secondaryLabel: profile.department ?? '-',
                showChevron: false,
              ),
              ListRow(
                icon: LucideIcons.mail,
                label: 'Email',
                secondaryLabel: profile.email ?? '-',
                showChevron: false,
              ),
              ListRow(
                icon: LucideIcons.phone,
                label: 'Phone',
                secondaryLabel: profile.phone ?? '-',
                showChevron: false,
              ),
              ListRow(
                icon: LucideIcons.file_text,
                label: 'CNIC',
                secondaryLabel: profile.cnic ?? '-',
                showChevron: false,
                showDivider: false,
              ),
            ]),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Log Out',
            variant: 'secondary',
            onPressed: () => AuthScope.of(context).onLogout(),
          ),
        ],
      ),
    );
  }
}