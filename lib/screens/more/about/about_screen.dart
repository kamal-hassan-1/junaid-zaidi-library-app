import 'package:flutter/material.dart';

import '../../../data/about_content.dart';
import '../../../data/library_images.dart';
import '../../../theme/theme.dart';
import '../../../widgets/ui.dart';

/// About screen (mirrors the original app's
/// `app/(tabs)/more/about/index.js`): hero photo, short description, a
/// quoted message from the library in-charge, a horizontally-scrolling
/// photo strip, and a grouped list of links into the other About
/// sub-screens (Facts / Rules / Staff / Floor Plan).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.asset(
                    'assets/library-front-leftAngle-view.jpg',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x7A000000),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          child: ClipOval(
                            child: Image(
                              image: const AssetImage(logoImagePath),
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const AppText(
                          'Junaid Zaidi Library, CUI Islamabad',
                          variant: 'caption',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Heading(level: 5, text: 'Description'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppText(
              aboutDescription,
              variant: 'bodyBase',
              tone: 'secondary',
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Heading(level: 5, text: 'Message from the Library In-Charge'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.background.secondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    '"${inchargeMessage.message}"',
                    variant: 'bodyBase',
                    tone: 'secondary',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    '— ${inchargeMessage.name}',
                    variant: 'bodySmall',
                    tone: 'tertiary',
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Heading(level: 5, text: 'Library Pictures'),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final img in libraryImages.take(8))
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.asset(
                          img.assetPath,
                          width: 160,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          _groupedList(colors, [
            for (var i = 0; i < aboutLinks.length; i++)
              ListRow(
                icon: aboutLinks[i].icon,
                label: aboutLinks[i].label,
                onTap: () => Navigator.of(context).pushNamed(aboutLinks[i].routeName),
                showDivider: i < aboutLinks.length - 1,
              ),
          ]),
        ],
      ),
    );
  }
}

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
