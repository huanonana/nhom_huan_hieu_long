import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_booking_repository.dart';
import '../../homestay/data/firestore_homestay_repository.dart';
import '../../homestay/data/firestore_room_repository.dart';

final firestoreInstanceProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firestoreBookingRepositoryProvider = Provider<FirestoreBookingRepository>(
  (ref) => FirestoreBookingRepository(ref.watch(firestoreInstanceProvider)),
);

final firestoreHomestayRepositoryProvider =
    Provider<FirestoreHomestayRepository>(
      (ref) =>
          FirestoreHomestayRepository(ref.watch(firestoreInstanceProvider)),
    );

final firestoreRoomRepositoryProvider = Provider<FirestoreRoomRepository>(
  (ref) => FirestoreRoomRepository(ref.watch(firestoreInstanceProvider)),
);

/// Opt-in backend selector; local demo storage remains the default until the
/// Firebase project has been configured and the UI has been migrated.
final useFirebaseBackendProvider = Provider<bool>(
  (ref) => const String.fromEnvironment('HHL_DATA_BACKEND') == 'firebase',
);
