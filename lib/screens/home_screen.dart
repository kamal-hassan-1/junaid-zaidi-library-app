import 'package:flutter/material.dart';

import '../data/home_resources.dart';
import '../data/library_images.dart';
import '../navigation/app_tab_scope.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// Home tab: hero banner, search box, and the 2-column resource shortcut
/// grid. Mirrors app/(tabs)/index.js.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    return ScreenContainer(
      scroll: true,
      backgroundImage: const AssetImage(homeBackgroundImagePath),
      backgroundImageOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner — real library building photo with a brand-color
          // overlay. The overlay uses exactly 0.451 alpha, matching the
          // original's `${colors.brand}73` hex-alpha suffix (0x73 = 115/255
          // ≈ 0.451).
          Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: shadow.border,
              boxShadow: shadow.boxShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image(
                    image: const AssetImage(homeBackgroundImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    color: colors.brand.withValues(alpha: 0.451),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          alignment: Alignment.center,
                          child: const Image(
                            image: AssetImage(logoImagePath),
                            width: 55,
                            height: 55,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Heading(
                          level: 4,
                          tone: 'onBrand',
                          text: 'Junaid Zaidi Library',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Opacity(
                          opacity: 0.85,
                          child: const AppText(
                            'COMSATS University Islamabad',
                            variant: 'bodySmall',
                            tone: 'onBrand',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SearchInput(
            value: _query,
            onChanged: (v) => setState(() => _query = v),
            onClear: () => setState(() => _query = ''),
            placeholder: 'Search for books...',
          ),

          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.ms),
            child: Heading(level: 5, text: 'Resources'),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppGrid.gutter) / 2;
              final rows = <Widget>[];
              for (var i = 0; i < homeResources.length; i += 2) {
                final pair = homeResources.skip(i).take(2).toList();
                if (rows.isNotEmpty) {
                  rows.add(const SizedBox(height: AppSpacing.md));
                }
                rows.add(
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final resource in pair)
                        SizedBox(
                          width: cardWidth,
                          child: ResourceCard(
                            icon: resource.icon,
                            title: resource.title,
                            subtitle: resource.subtitle,
                            accent: resource.accent,
                            onTap: resource.opensExploreSpaces
                                ? () => AppTabScope.of(context).goToTab(AppTabs.exploreSpaces)
                                : null,
                          ),
                        ),
                    ],
                  ),
                );
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
            },
          ),
        ],
      ),
    );
  }
}
