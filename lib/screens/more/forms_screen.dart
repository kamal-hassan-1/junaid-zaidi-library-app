import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/library_forms.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';

/// Library forms (Google Forms + downloadable PDFs). Shared list with the
/// Services tab Forms subsection; reached from More → Forms.
class FormsScreen extends StatelessWidget {
  const FormsScreen({super.key});

  Future<void> _openForm(BuildContext context, LibraryFormLink form) async {
    final confirmed = await showRedirectConfirmPopup(
      context,
      message: form.confirmMessage,
    );
    if (!confirmed) return;
    await launchUrl(Uri.parse(form.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final shadow = cardShadowDecoration(colors);

    return ScreenContainer(
      scroll: true,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background.secondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: shadow.border,
          boxShadow: shadow.boxShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < libraryForms.length; i++)
              ListRow(
                icon: libraryForms[i].icon,
                label: libraryForms[i].title,
                accent: libraryForms[i].accent,
                opensExternally: true,
                onTap: () => _openForm(context, libraryForms[i]),
                showDivider: i < libraryForms.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}
