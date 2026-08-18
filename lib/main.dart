import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_bootstrap.dart';
import 'navigation/theme_scope.dart';
import 'screens/auth/auth_gate.dart';
import 'services/notification_service.dart';
import 'services/theme_prefs.dart';
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
  // Sets up the local-notifications plugin + device timezone. Doesn't
  // request permission itself — that only happens once My Books actually
  // has something to remind about, see NotificationService.
  unawaited(NotificationService.instance.init());

  final isDarkMode = await ThemePrefs().isDarkMode();

  runApp(JunaidZaidiLibraryApp(initialDarkMode: isDarkMode));
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
/// Theme defaults to light and is toggled in More — it does not follow the
/// OS appearance setting.
class JunaidZaidiLibraryApp extends StatefulWidget {
  final bool initialDarkMode;

  const JunaidZaidiLibraryApp({super.key, required this.initialDarkMode});

  @override
  State<JunaidZaidiLibraryApp> createState() => _JunaidZaidiLibraryAppState();
}

class _JunaidZaidiLibraryAppState extends State<JunaidZaidiLibraryApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
  }

  Future<void> _setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) return;
    setState(() => _isDarkMode = enabled);
    await ThemePrefs().setDarkMode(enabled);
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      isDarkMode: _isDarkMode,
      setDarkMode: _setDarkMode,
      child: MaterialApp(
        title: 'Junaid Zaidi Library',
        debugShowCheckedModeBanner: false,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: _materialTheme(lightColors),
        darkTheme: _materialTheme(darkColors),
        builder: (context, child) {
          return AppThemeProvider(
            isDarkMode: _isDarkMode,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AuthGate(),
      ),
    );
  }
}
