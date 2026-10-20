import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/firestore_booking_repository.dart';
import '../../homestay/data/firestore_homestay_repository.dart';
import '../../homestay/data/firestore_room_repository.dart';
import '../../homestay/domain/catalog.dart';
import '../../review/domain/review.dart';
import '../domain/booking.dart';
import '../../auth/presentation/auth_provider.dart';

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

final firestoreHomestaysProvider = StreamProvider<List<Homestay>>(
  (ref) => ref.watch(firestoreHomestayRepositoryProvider).watchAll(),
);
final firestoreRoomsProvider = StreamProvider<List<Room>>(
  (ref) => ref.watch(firestoreRoomRepositoryProvider).watchAll(),
);
final firestoreBookingsProvider = StreamProvider<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return const Stream.empty();
  final repository = ref.watch(firestoreBookingRepositoryProvider);
  return user.role.name == 'host'
      ? repository.watchForHost(user.uid)
      : repository.watchForGuest(user.uid);
});
final firestoreReviewsProvider = StreamProvider<List<StayReview>>(
  (ref) => ref
      .watch(firestoreInstanceProvider)
      .collection('reviews')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => StayReview.fromFirestore(doc.data()))
            .toList(growable: false),
      ),
);

/// Local test containers use demo data unless the app boot enables Firebase.
final useFirebaseBackendProvider = Provider<bool>((ref) => false);
