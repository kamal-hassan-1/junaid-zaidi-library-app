import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

Future<FirebaseApp>? _firebaseReady;

/// Completes when [Firebase.initializeApp] finishes. Safe to call [startFirebase]
/// more than once (hot restart). AuthGate awaits this before using Auth APIs.
Future<FirebaseApp> get firebaseReady =>
    _firebaseReady ??= Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

void startFirebase() {
  _firebaseReady ??= Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
