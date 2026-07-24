import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../data/more_menu.dart';
import '../../models/profile_data.dart';
import '../../navigation/auth_scope.dart';
import '../../navigation/routes.dart';
import '../../services/profile_loader.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

Widget groupedList(SemanticColors colors, List<Widget> rows) {
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

const Map<MoreMenuSection, String> _sectionLabels = {
  MoreMenuSection.library: 'Library',
  MoreMenuSection.community: 'Community',
};

Widget _buildSectionList(BuildContext context, SemanticColors colors, MoreMenuSection section) {
  final items = moreMenu.where((item) => item.section == section).toList();
  return groupedList(colors, [
    for (var i = 0; i < items.length; i++)
      ListRow(
        icon: items[i].icon,
        label: items[i].label,
        accent: items[i].accent,
        onTap: items[i].routeName != null
            ? () => Navigator.of(context).pushNamed(items[i].routeName!)
            : null,
        badge: items[i].routeName == null
            ? const AppBadge(label: 'Coming soon', intent: 'warning')
            : null,
        showDivider: i < items.length - 1,
      ),
  ]);
}

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
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

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppText(
              'Account, resources & support',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppCard(
              onTap: () => Navigator.of(context).pushNamed(MoreRoutes.profile),
              child: _buildHeroRow(colors, isGuest),
            ),
          ),
          for (final section in [MoreMenuSection.library, MoreMenuSection.community])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Heading(
                      level: 5,
                      tone: 'tertiary',
                      text: _sectionLabels[section]!,
                    ),
                  ),
                  _buildSectionList(context, colors, section),
                ],
              ),
            ),
          const AppText(
            'Junaid Zaidi Library - v1.0.0',
            variant: 'caption',
            tone: 'tertiary',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroRow(SemanticColors colors, bool isGuest) {
    if (isGuest) {
      return Row(
        children: [
          Icon(LucideIcons.user, size: 36, color: colors.icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText('Browsing as guest', variant: 'bodyBase'),
                const SizedBox(height: AppSpacing.xs),
                AppText('Tap to sign in', variant: 'bodySmall', tone: 'secondary'),
              ],
            ),
          ),
          Icon(LucideIcons.chevron_right, size: 18, color: colors.icon),
        ],
      );
    }

    if (_isLoading && _profile == null) {
      return Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          AppText('Loading profile...', variant: 'bodyBase', tone: 'secondary'),
        ],
      );
    }

    final profile = _profile ??
        const ProfileData(fullName: 'Profile unavailable', registrationNumber: '', isLimited: true);

    return Row(
      children: [
        AppAvatar(name: profile.fullName),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(profile.fullName, variant: 'bodyBase'),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                profile.registrationNumber,
                variant: 'bodySmall',
                tone: 'secondary',
              ),
            ],
          ),
        ),
        Icon(LucideIcons.chevron_right, size: 18, color: colors.icon),
      ],
    );
  }
}