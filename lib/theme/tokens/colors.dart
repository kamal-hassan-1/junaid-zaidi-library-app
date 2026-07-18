import 'package:flutter/widgets.dart';

/// Raw palette definitions — single source of truth for all hex values.
///
/// Five 10-step scales (50 lightest -> 950 darkest). Brand identity: Junaid
/// Zaidi Library / COMSATS University Islamabad. Base (Brand) = blue tones.
///
/// RULE: screens and widgets must NEVER use these maps directly. Always go
/// through the semantic layer (theme/semantic/light.dart, dark.dart).
class AppPalette {
  AppPalette._();

  static const Map<int, Color> gray = {
    50: Color(0xFFF8F9FA),
    100: Color(0xFFF1F3F5),
    200: Color(0xFFE2E6EA),
    300: Color(0xFFCDD3DA),
    400: Color(0xFF9AA5B4),
    500: Color(0xFF6E7F96),
    600: Color(0xFF4A5568),
    700: Color(0xFF35404F),
    800: Color(0xFF222D3A),
    900: Color(0xFF141C26),
    950: Color(0xFF0A1018),
  };

  static const Map<int, Color> base = {
    50: Color(0xFFEFF6FF),
    100: Color(0xFFDBEAFE),
    200: Color(0xFFBFDBFE),
    300: Color(0xFF93C5FD),
    400: Color(0xFF60A5FA),
    500: Color(0xFF3B82F6),
    600: Color(0xFF2563EB),
    700: Color(0xFF1D4ED8), // Brand Color (Base 700)
    800: Color(0xFF1E40AF),
    900: Color(0xFF1E3A8A),
    950: Color(0xFF172554),
  };

  static const Map<int, Color> red = {
    50: Color(0xFFFEF2F2),
    100: Color(0xFFFEE2E2),
    200: Color(0xFFFECACA),
    300: Color(0xFFFCA5A5),
    400: Color(0xFFF87171),
    500: Color(0xFFEF4444),
    600: Color(0xFFDC2626), // Error Color
    700: Color(0xFFB91C1C),
    800: Color(0xFF991B1B),
    900: Color(0xFF7F1D1D),
    950: Color(0xFF450A0A),
  };

  static const Map<int, Color> green = {
    50: Color(0xFFF0FDF4),
    100: Color(0xFFDCFCE7),
    200: Color(0xFFBBF7D0),
    300: Color(0xFF86EFAC),
    400: Color(0xFF4ADE80),
    500: Color(0xFF22C55E),
    600: Color(0xFF16A34A), // Success Color
    700: Color(0xFF15803D),
    800: Color(0xFF166534),
    900: Color(0xFF14532D),
    950: Color(0xFF052E16),
  };

  static const Map<int, Color> yellow = {
    50: Color(0xFFFFFBEB),
    100: Color(0xFFFEF3C7),
    200: Color(0xFFFDE68A),
    300: Color(0xFFFCD34D),
    400: Color(0xFFFBBF24),
    500: Color(0xFFF59E0B),
    600: Color(0xFFD97706), // Warning Color
    700: Color(0xFFB45309),
    800: Color(0xFF92400E),
    900: Color(0xFF78350F),
    950: Color(0xFF451A03),
  };
}
