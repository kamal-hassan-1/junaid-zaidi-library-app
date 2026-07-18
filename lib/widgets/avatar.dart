import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'app_text.dart';

const Map<String, double> _avatarSizes = {
  'small': 40,
  'medium': 56,
  'large': 80,
};

/// Reuses Button's size scale (small/medium/large) rather than inventing a
/// new one. Falls back to initials on a brand-tinted background when no
/// image is provided.
class AppAvatar extends StatelessWidget {
  final ImageProvider? image;
  final String name;
  final String size;

  const AppAvatar({
    super.key,
    this.image,
    this.name = '',
    this.size = 'medium',
  });

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final dimension = _avatarSizes[size] ?? _avatarSizes['medium']!;

    if (image != null) {
      return ClipOval(
        child: Image(
          image: image!,
          width: dimension,
          height: dimension,
          fit: BoxFit.cover,
        ),
      );
    }

    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2);
    final initials = words.map((w) => w[0].toUpperCase()).join();

    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: withOpacity(colors.brand, 0.12),
      ),
      alignment: Alignment.center,
      child: AppText(
        initials,
        variant: size == 'large' ? 'h4' : 'bodyBase',
        tone: 'brand',
      ),
    );
  }
}
