import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/library_location.dart';
import '../../theme/theme.dart';
import '../../widgets/ui.dart';
import 'more_screen.dart' show groupedList;
import 'map_screen.dart';

/// Contact Us screen — real contact details from the library website
/// (library.comsats.edu.pk/ContactUs.aspx), laid out as the same grouped
/// list style used elsewhere in More/About, rather than an embedded web
/// form.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const _phone = '051-90495065';
  static const _email = 'info@comsats.edu.pk';
  static const _facebookUrl = 'https://www.facebook.com/LIS.CIIT.Islamabad';
  static const _twitterUrl = 'https://twitter.com/zaidilibrary';

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);

    return ScreenContainer(
      scroll: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Heading(level: 5, tone: 'tertiary', text: 'Get in touch'),
          ),
          groupedList(colors, [
            ListRow(
              icon: LucideIcons.map_pin,
              label: 'Address',
              secondaryLabel: libraryLocation.address,
              accent: AppAccent.brand,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MapScreen()),
              ),
            ),
            ListRow(
              icon: LucideIcons.phone,
              label: 'Phone',
              secondaryLabel: _phone,
              accent: AppAccent.success,
              onTap: () => _open('tel:$_phone'),
            ),
            ListRow(
              faIcon: FontAwesomeIcons.envelope,
              label: 'Email',
              secondaryLabel: _email,
              accent: AppAccent.warning,
              onTap: () => _open('mailto:$_email'),
              showDivider: false,
            ),
          ]),

          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Heading(level: 5, tone: 'tertiary', text: 'Follow us'),
          ),
          groupedList(colors, [
            ListRow(
              faIcon: FontAwesomeIcons.facebook,
              label: 'Facebook',
              secondaryLabel: 'LIS.CIIT.Islamabad',
              accent: AppAccent.brand,
              onTap: () => _open(_facebookUrl),
            ),
            ListRow(
              faIcon: FontAwesomeIcons.xTwitter,
              label: 'Twitter / X',
              secondaryLabel: '@zaidilibrary',
              accent: AppAccent.brand,
              onTap: () => _open(_twitterUrl),
              showDivider: false,
            ),
          ]),
        ],
      ),
    );
  }
}