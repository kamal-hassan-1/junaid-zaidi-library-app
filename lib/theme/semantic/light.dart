import 'package:flutter/widgets.dart';

import '../tokens/colors.dart';
import 'semantic_colors.dart';

const Color _white = Color(0xFFFFFFFF);

/// Light mode semantic mapping.
///
/// Brand color: Base 700 (#1D4ED8) — institutional blue, unchanged across
/// themes. Status colors (error/success/warning) also stay constant.
final SemanticColors lightColors = SemanticColors(
  mode: 'light',
  background: BackgroundTiers(
    primary: AppPalette.gray[50]!,
    secondary: AppPalette.gray[100]!,
    tertiary: AppPalette.gray[200]!,
  ),
  border: AppPalette.gray[300]!,
  icon: AppPalette.gray[500]!,
  text: TextTiers(
    primary: AppPalette.gray[950]!,
    secondary: AppPalette.gray[600]!,
    tertiary: AppPalette.gray[400]!,
    onBrand: _white,
  ),
  brand: AppPalette.base[700]!,
  brandPressed: AppPalette.base[800]!,
  error: AppPalette.red[600]!,
  success: AppPalette.green[600]!,
  warning: AppPalette.yellow[600]!,
  intents: IntentPalette(
    info: IntentColors(
      light: ColorPair(bg: AppPalette.base[50]!, fg: AppPalette.base[700]!),
      filled: ColorPair(bg: AppPalette.base[700]!, fg: _white),
    ),
    warning: IntentColors(
      light: ColorPair(bg: AppPalette.yellow[50]!, fg: AppPalette.yellow[700]!),
      filled: ColorPair(bg: AppPalette.yellow[600]!, fg: _white),
    ),
    success: IntentColors(
      light: ColorPair(bg: AppPalette.green[50]!, fg: AppPalette.green[700]!),
      filled: ColorPair(bg: AppPalette.green[600]!, fg: _white),
    ),
    error: IntentColors(
      light: ColorPair(bg: AppPalette.red[50]!, fg: AppPalette.red[600]!),
      filled: ColorPair(bg: AppPalette.red[600]!, fg: _white),
    ),
  ),
  snackbar: SnackbarColors(
    background: AppPalette.gray[950]!,
    primaryText: AppPalette.gray[50]!,
    secondaryText: AppPalette.gray[300]!,
    actionText: AppPalette.gray[50]!,
  ),
);
