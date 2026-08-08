import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_bootstrap.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/semantic/dark.dart';
import 'theme/semantic/light.dart';
import 'theme/theme.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Hold the solid-color native plate only until SplashScreen's first frame.
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  GoogleFonts.config.allowRuntimeFetching = false;

  // Kick off Firebase without awaiting — runApp paints SplashScreen ASAP,
  // so Android 12+ isn't stuck on a blank bg during SDK init.
  startFirebase();

  runApp(const JunaidZaidiLibraryApp());
}

ThemeData _materialTheme(SemanticColors colors) {
  return ThemeData(
    useMaterial3: true,
    brightness: colors.isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: colors.background.primary,
    splashFactory: NoSplash.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: colors.text.primary,
      iconTheme: IconThemeData(color: colors.text.primary),
      titleTextStyle: AppTypography.h5
          .toTextStyle(color: colors.text.primary)
          .copyWith(fontSize: AppTypography.bodyLarge.fontSize),
    ),
  );
}

/// App root: mirrors app/_layout.js (ThemeProvider + Stack) plus
/// app/(tabs)/_layout.js's tab bar, combined into one shell since Flutter
/// doesn't split "root layout" and "tab layout" into separate files the
/// way expo-router does.
///
/// `home` points at AuthGate — AuthGate decides which shell to show based
/// on Koha/Firebase session state.
///
/// Theme follows the OS light/dark setting (`ThemeMode.system`). Semantic
/// colors come from [AppThemeProvider] inside [MaterialApp.builder] so they
/// stay in sync with Material's resolved brightness.
class JunaidZaidiLibraryApp extends StatelessWidget {
  const JunaidZaidiLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Junaid Zaidi Library',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _materialTheme(lightColors),
      darkTheme: _materialTheme(darkColors),
      builder: (context, child) {
        return AppThemeProvider(
          brightness: Theme.of(context).brightness,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}
