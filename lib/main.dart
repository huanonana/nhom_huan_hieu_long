import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/firebase/firebase_document_store.dart';
import 'core/firebase/firebase_live_sync.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/state/demo_storage.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'firebase_options.dart';

const _firebaseEnabled = bool.fromEnvironment(
  'HHL_USE_FIREBASE',
  defaultValue: false,
);
const _firebaseEmulatorsEnabled = bool.fromEnvironment(
  'HHL_USE_FIREBASE_EMULATORS',
  defaultValue: false,
);
const _firebaseEmulatorHost = String.fromEnvironment(
  'HHL_FIREBASE_EMULATOR_HOST',
  defaultValue: '127.0.0.1',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseAuthRepository? firebaseAuth;
  FirebaseDocumentStore? documentStore;
  String? firebaseInitializationError;
  if (_firebaseEnabled) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (_firebaseEmulatorsEnabled) {
        await FirebaseAuth.instance.useAuthEmulator(_firebaseEmulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(
          _firebaseEmulatorHost,
          8180,
        );
      }
      firebaseAuth = FirebaseAuthRepository();
      documentStore = FirebaseDocumentStore();
    } catch (_) {
      // Keep the local experience available if Firebase configuration fails.
      firebaseInitializationError =
          'Firebase chưa khởi tạo được. App đang chạy bằng dữ liệu trên thiết bị.';
    }
  }
  // Local mode remains the default for deterministic offline demos and tests.
  final container = await DemoStorage.device(
    authRepository: firebaseAuth,
    firebaseMode: firebaseAuth != null,
    documentStore: documentStore,
  ).load();
  if (firebaseInitializationError case final String message) {
    container.read(storageNoticeProvider.notifier).state = message;
  }
  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));

  // Do not hold the Flutter splash screen while several Firestore collections
  // are being read. The local catalog is available immediately; cloud data is
  // merged in the background and failures surface as a recoverable notice.
  if (firebaseAuth != null && documentStore != null) {
    FirebaseLiveSync(container, documentStore).start();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Homestay HHL',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    scrollBehavior: AppScrollBehavior(),
    locale: const Locale('vi'),
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
  );
}
