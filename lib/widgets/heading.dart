import 'package:flutter/widgets.dart';

import 'app_text.dart';

const Map<String, String> _levelToVariant = {
  'display1': 'display1',
  'display2': 'display2',
  '1': 'h1',
  '2': 'h2',
  '3': 'h3',
  '4': 'h4',
  '5': 'h5',
};

/// Page/section heading. Wraps [AppText] and restricts it to the design
/// system's heading/display tiers via a shorthand `level` param (int 1-5,
/// or the strings 'display1'/'display2'), so screens never have to
/// remember variant string names.
class Heading extends StatelessWidget {
  final String text;
  final dynamic level;
  final String tone;
  final TextStyle? style;
  final TextAlign? textAlign;

  const Heading({
    super.key,
    required this.text,
    this.level = 3,
    this.tone = 'primary',
    this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final variant = _levelToVariant[level.toString()] ?? 'h3';
    return AppText(
      text,
      variant: variant,
      tone: tone,
      style: style,
      textAlign: textAlign,
    );
  }
}
