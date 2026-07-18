import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// 1px hairline divider, Border Color — the same divider ListRow uses
/// internally.
class AppDivider extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const AppDivider({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final colors = useTheme(context);
    final divider = Container(height: 1, color: colors.border);
    if (margin == null) {
      return divider;
    }
    return Padding(padding: margin!, child: divider);
  }
}
