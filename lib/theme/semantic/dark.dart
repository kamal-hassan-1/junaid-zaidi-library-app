import '../tokens/colors.dart';
import 'semantic_colors.dart';

/// Dark mode semantic mapping.
///
/// Key rule: brand and status colors do NOT shift between themes — Base 700,
/// Red 600, Green 600, Yellow 600 are identical in both light and dark. Only
/// gray-based structural tokens invert. Do not darken the brand color here.
final SemanticColors darkColors = SemanticColors(
  mode: 'dark',
  background: BackgroundTiers(
    primary: AppPalette.gray[950]!,
    secondary: AppPalette.gray[900]!,
    tertiary: AppPalette.gray[800]!,
  ),
  border: AppPalette.gray[700]!,
  icon: AppPalette.gray[400]!,
  text: TextTiers(
    primary: AppPalette.gray[50]!,
    secondary: AppPalette.gray[300]!,
    tertiary: AppPalette.gray[500]!,
    onBrand: AppPalette.gray[50]!,
  ),
  brand: AppPalette.base[700]!, // UNCHANGED per key rule
  brandPressed: AppPalette.base[800]!, // UNCHANGED
  error: AppPalette.red[600]!, // UNCHANGED
  success: AppPalette.green[600]!, // UNCHANGED
  warning: AppPalette.yellow[600]!, // UNCHANGED
  intents: IntentPalette(
    info: IntentColors(
      light: ColorPair(bg: AppPalette.base[950]!, fg: AppPalette.base[200]!),
      filled: ColorPair(bg: AppPalette.base[700]!, fg: AppPalette.gray[50]!),
    ),
    warning: IntentColors(
      light: ColorPair(bg: AppPalette.yellow[950]!, fg: AppPalette.yellow[200]!),
      filled: ColorPair(bg: AppPalette.yellow[600]!, fg: AppPalette.gray[50]!),
    ),
    success: IntentColors(
      light: ColorPair(bg: AppPalette.green[950]!, fg: AppPalette.green[200]!),
      filled: ColorPair(bg: AppPalette.green[600]!, fg: AppPalette.gray[50]!),
    ),
    error: IntentColors(
      light: ColorPair(bg: AppPalette.red[950]!, fg: AppPalette.red[200]!),
      filled: ColorPair(bg: AppPalette.red[600]!, fg: AppPalette.gray[50]!),
    ),
  ),
  snackbar: SnackbarColors(
    background: AppPalette.gray[800]!,
    primaryText: AppPalette.gray[50]!,
    secondaryText: AppPalette.gray[300]!,
    actionText: AppPalette.gray[50]!,
  ),
);
