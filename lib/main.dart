import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/semantic/light.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JunaidZaidiLibraryApp());
}

/// App root: mirrors app/_layout.js (ThemeProvider + Stack) plus
/// app/(tabs)/_layout.js's tab bar, combined into one shell since Flutter
/// doesn't split "root layout" and "tab layout" into separate files the
/// way expo-router does.
///
/// `home` now points at AuthGate (added Phase 2) instead of RootShell
/// directly — AuthGate decides which one to show based on Koha session
/// state.
class JunaidZaidiLibraryApp extends StatelessWidget {
  const JunaidZaidiLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppThemeProvider(
      child: MaterialApp(
        title: 'Junaid Zaidi Library',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: lightColors.background.primary,
          splashFactory: NoSplash.splashFactory,
          appBarTheme: AppBarTheme(
            backgroundColor: lightColors.background.primary,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: lightColors.text.primary,
            iconTheme: IconThemeData(color: lightColors.text.primary),
            titleTextStyle: AppTypography.h5
                .toTextStyle(color: lightColors.text.primary)
                .copyWith(fontSize: AppTypography.bodyLarge.fontSize),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}