import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/library_spaces.dart';
import '../theme/theme.dart';
import '../widgets/ui.dart';

/// In-app detail for one [LibrarySpace] — images + content from the library site.
class SpaceDetailScreen extends StatelessWidget {
  final LibrarySpace space;

  const SpaceDetailScreen({super.key, required this.space});

  Future<void> _openReservationEmail(BuildContext context, String email) async {
    final confirmed = await showRedirectConfirmPopup(
      context,
      message: 'This will open your email app to message $email.',
    );
    if (!confirmed) return;
    await launchUrl(
      Uri(scheme: 'mailto', path: email),
      mode: LaunchMode.externalApplication,
    );
  }

  Widget _reservationStepText(
    BuildContext context,
    String step,
    SemanticColors colors,
  ) {
    final email = space.reservationEmail;
    final baseStyle = AppTypography.bodyBase.toTextStyle(
      color: colors.text.secondary,
    );

    if (email == null || !step.contains(email)) {
      return AppText(step, variant: 'bodyBase', tone: 'secondary');
    }

    final index = step.indexOf(email);
    final before = step.substring(0, index);
    final after = step.substring(index + email.length);
    final linkStyle = baseStyle.copyWith(
      color: colors.brand,
      decoration: TextDecoration.underline,
      decorationColor: colors.brand,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => _openReservationEmail(context, email),
              child: Text(email, style: linkStyle),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SpaceImages(imagePaths: space.imagePaths),
          const SizedBox(height: AppSpacing.lg),
          for (final paragraph in space.paragraphs) ...[
            AppText(paragraph, variant: 'bodyBase', tone: 'primary'),
            const SizedBox(height: AppSpacing.md),
          ],
          if (space.conditions.isNotEmpty) ...[
            Heading(
              level: 5,
              text: space.conditionsTitle ?? 'Conditions',
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in space.conditions.asMap().entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.background.tertiary,
                      ),
                      alignment: Alignment.center,
                      child: AppText(
                        '${entry.key + 1}',
                        variant: 'bodySmall',
                        tone: 'secondary',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppText(
                        entry.value,
                        variant: 'bodyBase',
                        tone: 'primary',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (space.reservationSteps.isNotEmpty) ...[
            Heading(
              level: 5,
              text: space.reservationTitle ?? 'Reservation',
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.background.secondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < space.reservationSteps.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _reservationStepText(
                      context,
                      space.reservationSteps[i],
                      colors,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpaceImages extends StatelessWidget {
  final List<String> imagePaths;

  const _SpaceImages({required this.imagePaths});

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) return const SizedBox.shrink();

    if (imagePaths.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Image.asset(
          imagePaths.first,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imagePaths.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final width = imagePaths.length == 2
              ? (MediaQuery.sizeOf(context).width -
                      AppGrid.margin * 2 -
                      AppSpacing.sm) /
                  2
              : 240.0;
          return ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.asset(
              imagePaths[index],
              width: width,
              height: 200,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
