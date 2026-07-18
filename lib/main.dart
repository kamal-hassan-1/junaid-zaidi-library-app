import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/root_shell.dart';
import 'theme/semantic/light.dart';
import 'theme/theme.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const JunaidZaidiLibraryApp());
}

/// App root: mirrors app/_layout.js (ThemeProvider + Stack) plus
/// app/(tabs)/_layout.js's tab bar, combined into one shell since Flutter
/// doesn't split "root layout" and "tab layout" into separate files the way
/// expo-router does.
///
/// Note: the original app blocks first render behind expo-splash-screen
/// until Inter's weights finish loading via useFonts(). google_fonts here
/// fetches/caches Inter lazily instead (standard Flutter practice) and
/// falls back to the platform font for a frame rather than blocking render.
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
            // design.md §2.2: bodyLarge (19px) is the header title size step;
            // weight matches h5's Medium (500).
            titleTextStyle: AppTypography.h5
                .toTextStyle(color: lightColors.text.primary)
                .copyWith(fontSize: AppTypography.bodyLarge.fontSize),
          ),
        ),
        home: const RootShell(),
      ),
    );
  }
}
