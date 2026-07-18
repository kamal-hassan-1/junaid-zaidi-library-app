/// Spacing scale — strict 4pt grid. Identical in light and dark mode
/// (spacing is structural, not thematic).
class AppSpacing {
  const AppSpacing._();

  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double ms = 12;
  static const double md = 16;
  static const double ml = 20;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double xxxxl = 64;
  static const double xxxxxl = 80;
  static const double xxxxxxl = 96;
  static const double xxxxxxxl = 128;
  static const double xxxxxxxxl = 160;
}

/// Mobile grid spec: 402px reference width, 4 columns, 20px margin, 8px gutter.
class AppGrid {
  const AppGrid._();

  static const double referenceWidth = 402;
  static const int columns = 4;
  static const double margin = AppSpacing.ml;
  static const double gutter = AppSpacing.sm;
}
