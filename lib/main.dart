import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase/firebase_document_store.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/state/demo_storage.dart';
import 'core/state/app_state.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/booking/data/demo_booking_repository.dart';
import 'firebase_options.dart';

const _firebaseEnabled = bool.fromEnvironment(
  'HHL_USE_FIREBASE',
  defaultValue: false,
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
    unawaited(_syncInitialFirebaseData(container, firebaseAuth, documentStore));
  }
}

Future<void> _syncInitialFirebaseData(
  ProviderContainer container,
  FirebaseAuthRepository firebaseAuth,
  FirebaseDocumentStore documentStore,
) async {
  var hadSyncError = false;

  Future<List<T>> loadList<T>(
    String collection,
    Future<List<T>> request,
  ) async {
    try {
      // Android emulators can take several seconds to establish their first
      // Firestore gRPC connection after a cold start. Keep this sync in the
      // background and allow that initial connection time before showing a
      // recoverable offline notice.
      return await request.timeout(const Duration(seconds: 60));
    } catch (error) {
      hadSyncError = true;
      debugPrint(
        'Firebase startup sync failed for $collection (${error.runtimeType}).',
      );
      return <T>[];
    }
  }

  try {
    try {
      await firebaseAuth.currentProfile().timeout(const Duration(seconds: 8));
    } catch (error) {
      hadSyncError = true;
      debugPrint('Firebase profile load failed (${error.runtimeType}).');
    }
    // Load collections concurrently and keep the ones that are readable. This
    // lets public catalog data load even if a management collection is denied.
    final bookingsFuture = loadList(
      'bookings',
      documentStore.allBookingsForDemo(),
    );
    final homesFuture = loadList('homestays', documentStore.publicHomestays());
    final roomsFuture = loadList('rooms', documentStore.publicRooms());
    final reviewsFuture = loadList('reviews', documentStore.publicReviews());
    final financeFuture = loadList(
      'financeEntries',
      documentStore.allFinanceEntries(),
    );
    final staffFuture = loadList(
      'staffMembers',
      documentStore.allStaffMembers(),
    );
    final shiftsFuture = loadList(
      'staffShifts',
      documentStore.allStaffShifts(),
    );
    final bookings = await bookingsFuture;
    final homes = await homesFuture;
    final rooms = await roomsFuture;
    final reviews = await reviewsFuture;
    final financeEntries = await financeFuture;
    final staffMembers = await staffFuture;
    final staffShifts = await shiftsFuture;
    final repository = container.read(repositoryProvider);
    if (repository is! DemoBookingRepository) return;

    repository.mergeCloudBookings(bookings);
    repository.mergeCloudCatalog(homes: homes, rooms: rooms, reviews: reviews);
    if (financeEntries.isNotEmpty) {
      final merged = {
        for (final item in container.read(financeEntriesProvider))
          item.id: item,
        for (final item in financeEntries) item.id: item,
      };
      container.read(financeEntriesProvider.notifier).state = merged.values
          .toList();
    }
    if (staffMembers.isNotEmpty) {
      final merged = {
        for (final item in container.read(staffMembersProvider)) item.id: item,
        for (final item in staffMembers) item.id: item,
      };
      container.read(staffMembersProvider.notifier).state = merged.values
          .toList();
    }
    if (staffShifts.isNotEmpty) {
      final merged = {
        for (final item in container.read(staffShiftsProvider)) item.id: item,
        for (final item in staffShifts) item.id: item,
      };
      container.read(staffShiftsProvider.notifier).state = merged.values
          .toList();
    }
    container.read(storageNoticeProvider.notifier).state = hadSyncError
        ? 'Một số dữ liệu Firebase chưa đọc được. App vẫn hoạt động với dữ liệu trên thiết bị; kiểm tra kết nối và Rules.'
        : null;
    container.read(changesProvider.notifier).refreshFromStorage();
  } catch (_) {
    container.read(storageNoticeProvider.notifier).state =
        'Chưa đồng bộ được dữ liệu Firebase. App vẫn dùng dữ liệu trên thiết bị; kiểm tra kết nối và Firestore Rules.';
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
