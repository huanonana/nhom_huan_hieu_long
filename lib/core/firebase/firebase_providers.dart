import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_document_store.dart';

final firebaseModeProvider = Provider<bool>((ref) => false);
final firebaseDocumentStoreProvider = Provider<FirebaseDocumentStore?>(
  (ref) => null,
);
final firebaseSyncNoticeProvider = StateProvider<String?>((ref) => null);
