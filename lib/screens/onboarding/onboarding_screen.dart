import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/library_images.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// First-launch PageView onboarding. Shown once until [onFinished] is called
/// (Skip or Get Started). Persistence is owned by the caller via
/// [OnboardingPrefs].
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({super.key, required this.onFinished});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 4;

  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _pageCount - 1;
  bool get _isPhotoPage => _index == 0 || _index == 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (_isLast) {
      widget.onFinished();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => widget.onFinished();

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    final skipColor = _isPhotoPage
        ? Colors.white.withValues(alpha: 0.85)
        : colors.text.secondary;

    return Scaffold(
      backgroundColor: colors.background.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: const [
              _WelcomePage(),
              _DiscoverResourcesPage(),
              _LibraryServicesPage(),
              _ServicesFeaturesPage(),
            ],
          ),
          if (!_isLast)
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              right: AppGrid.margin - AppSpacing.sm,
              child: TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: skipColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                child: AppText(
                  'Skip',
                  variant: 'bodyBase',
                  style: TextStyle(
                    color: skipColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _OnboardingChrome(
              index: _index,
              pageCount: _pageCount,
              isLast: _isLast,
              isPhotoPage: _isPhotoPage,
              bottomPad: bottomPad,
              onPrimary: _goNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingChrome extends StatelessWidget {
  final int index;
  final int pageCount;
  final bool isLast;
  final bool isPhotoPage;
  final double bottomPad;
  final VoidCallback onPrimary;

  const _OnboardingChrome({
    required this.index,
    required this.pageCount,
    required this.isLast,
    required this.isPhotoPage,
    required this.bottomPad,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final onPhoto = isPhotoPage;
    final activeDot = onPhoto ? Colors.white : colors.brand;
    final inactiveDot = onPhoto
        ? Colors.white.withValues(alpha: 0.35)
        : colors.border;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPhoto
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.55),
                ],
              )
            : null,
        color: onPhoto ? null : colors.background.primary,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppGrid.margin,
          AppSpacing.md,
          AppGrid.margin,
          AppSpacing.lg + bottomPad,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final active = i == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? activeDot : inactiveDot,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: isLast ? 'Get Started' : 'Next',
              variant: 'primary',
              onPressed: onPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return _PhotoBackdrop(
      assetPath: libraryGroundFloorImagePath,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppGrid.margin,
            AppSpacing.xxl,
            AppGrid.margin,
            160,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Heading(
                text: 'Welcome to Junaid Zaidi Library',
                level: 2,
                style: _onPhotoTitleStyle,
              ),
              const SizedBox(height: AppSpacing.md),
              AppText(
                'Access books, digital resources, study spaces and library services from anywhere.',
                variant: 'bodyLarge',
                style: _onPhotoBodyStyle,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscoverResourcesPage extends StatelessWidget {
  const _DiscoverResourcesPage();

  static const _features = <(IconData, String)>[
    (LucideIcons.search, 'Printed Books'),
    (LucideIcons.book_open, 'eBooks'),
    (LucideIcons.file_text, 'Scholarly Journals'),
    (LucideIcons.graduation_cap, 'Theses & Dissertations'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final height = MediaQuery.sizeOf(context).height;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppGrid.margin,
          AppSpacing.lg,
          AppGrid.margin,
          150,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Heading(
              text: 'Discover Resources',
              level: 3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Search thousands of academic resources from one place.',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _features.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final (icon, label) = _features[i];
                  return _FeatureChip(icon: icon, label: label);
                },
              ),
            ),
            SizedBox(
              height: height * 0.22,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Image.asset(
                  holdingPhoneImagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    LucideIcons.smartphone,
                    size: 72,
                    color: colors.icon,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryServicesPage extends StatelessWidget {
  const _LibraryServicesPage();

  static const _services = <(IconData, String)>[
    (LucideIcons.book_marked, 'Borrow Books'),
    (LucideIcons.bookmark, 'Reserve Books'),
    (LucideIcons.refresh_cw, 'Renew Loans'),
    (LucideIcons.message_circle, 'Ask a Librarian'),
    (LucideIcons.microscope, 'Research Support'),
    (LucideIcons.lightbulb, 'Information Literacy'),
    (LucideIcons.library, 'Interlibrary Services'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final height = MediaQuery.sizeOf(context).height;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppGrid.margin,
          AppSpacing.lg,
          AppGrid.margin,
          150,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Heading(
              text: 'Library Services',
              level: 3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppText(
              'Everything you need for borrowing, research, and support.',
              variant: 'bodyBase',
              tone: 'secondary',
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: height * 0.28,
              child: SvgPicture.asset(
                librarianSvgImagePath,
                fit: BoxFit.contain,
                allowDrawingOutsideViewBox: false,
                placeholderBuilder: (_) => Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.brand,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _services.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, i) {
                  final (icon, label) = _services[i];
                  return _FeatureChip(icon: icon, label: label, compact: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesFeaturesPage extends StatelessWidget {
  const _ServicesFeaturesPage();

  static const _features = <(IconData, String)>[
    (LucideIcons.door_open, 'Study Room Booking'),
    (LucideIcons.newspaper, 'Latest News'),
    (LucideIcons.calendar, 'Library Events'),
    (LucideIcons.monitor, 'Digital Library'),
    (LucideIcons.list, 'Reading Lists'),
    (LucideIcons.bell, 'Notifications'),
    (LucideIcons.ellipsis, 'And much more...'),
  ];

  @override
  Widget build(BuildContext context) {
    return _PhotoBackdrop(
      assetPath: libraryFrontLeftAngleImagePath,
      alignment: const Alignment(0.12, 0),
      overlayLight: true,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppGrid.margin,
            AppSpacing.lg,
            AppGrid.margin,
            160,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Heading(
                text: 'Services & Features',
                level: 3,
                style: _onPhotoTitleStyle.copyWith(height: null),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                'Book spaces, stay updated, and explore more from your phone.',
                variant: 'bodyBase',
                style: _onPhotoBodyStyle,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _features.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final (icon, label) = _features[i];
                    return _FeatureChip(
                      icon: icon,
                      label: label,
                      compact: true,
                      onDark: true,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

const _onPhotoTitleStyle = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w700,
  height: 1.15,
  shadows: [
    Shadow(color: Color(0xCC000000), blurRadius: 10, offset: Offset(0, 1)),
    Shadow(color: Color(0x99000000), blurRadius: 22, offset: Offset(0, 4)),
  ],
);

const _onPhotoBodyStyle = TextStyle(
  color: Color(0xFFF2F2F2),
  height: 1.45,
  shadows: [
    Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 1)),
    Shadow(color: Color(0x88000000), blurRadius: 16, offset: Offset(0, 3)),
  ],
);

class _PhotoBackdrop extends StatelessWidget {
  final String assetPath;
  final Widget child;
  final Alignment alignment;

  /// Softer wash so more of the photo comes through.
  final bool overlayLight;

  const _PhotoBackdrop({
    required this.assetPath,
    required this.child,
    this.alignment = Alignment.center,
    this.overlayLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = overlayLight
        ? [
            Colors.black.withValues(alpha: 0.28),
            Colors.black.withValues(alpha: 0.24),
            Colors.black.withValues(alpha: 0.42),
            Colors.black.withValues(alpha: 0.55),
          ]
        : [
            Colors.black.withValues(alpha: 0.42),
            Colors.black.withValues(alpha: 0.38),
            Colors.black.withValues(alpha: 0.62),
            Colors.black.withValues(alpha: 0.78),
          ];

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: alignment,
        ),
        // Soft wash overall + stronger scrim only through the lower half
        // where copy sits — keeps the photo readable without flattening it.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 0.7, 1.0],
              colors: colors,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;
  final bool onDark;

  const _FeatureChip({
    required this.icon,
    required this.label,
    this.compact = false,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final accent = colors.brand;
    final bg = onDark
        ? Colors.black.withValues(alpha: 0.45)
        : withOpacity(accent, 0.10);
    final fg = onDark ? Colors.white : colors.text.primary;
    final iconColor = onDark ? Colors.white : accent;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: compact ? AppSpacing.sm : AppSpacing.ms,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.18))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 32 : 36,
            height: compact ? 32 : 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : withOpacity(accent, 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: AppText(
              label,
              variant: 'bodyBase',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
