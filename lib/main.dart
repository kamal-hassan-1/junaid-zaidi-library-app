import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'repositories/repository_registry.dart';
import 'repositories/repository_scope.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/semantic/light.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const JunaidZaidiLibraryApp());
}

/// The app's repositories, chosen by `DataSourceConfig` and built once for the
/// process. A top-level `final` is lazily initialized in Dart, so this costs
/// nothing until the first build.
///
/// It lives here rather than as a widget field so that
/// `const JunaidZaidiLibraryApp()` keeps working — the registry is not const,
/// and threading it through the constructor would break every existing caller.
final RepositoryRegistry _repositories = RepositoryRegistry.fromConfig();

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
    // Outermost, so that everything the app can reach — including routes
    // pushed by nested Navigators and dialogs shown in the overlay — sits
    // below it.
    return RepositoryScope(
      repositories: _repositories,
      child: AppThemeProvider(
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
      ),
    );
  }
}