import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/catalog.dart';

class FirestoreHomestayRepository {
  FirestoreHomestayRepository(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _homes =>
      _firestore.collection('homestays');

  Stream<List<Homestay>> watchAll() => _homes.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => Homestay.fromFirestore(doc.data(), id: doc.id))
        .toList(growable: false),
  );

  Stream<List<Homestay>> watchByHost(String hostId) => _homes
      .where('hostId', isEqualTo: hostId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Homestay.fromFirestore(doc.data(), id: doc.id))
            .toList(growable: false),
      );

  Future<Homestay?> get(String id) async {
    final snapshot = await _homes.doc(id).get();
    return snapshot.exists
        ? Homestay.fromFirestore(snapshot.data()!, id: snapshot.id)
        : null;
  }

  Future<void> save(Homestay home) =>
      _homes.doc(home.id).set(home.toFirestore(), SetOptions(merge: true));

  Future<void> delete(String id) async {
    final rooms = await _firestore
        .collection('rooms')
        .where('homestayId', isEqualTo: id)
        .limit(1)
        .get();
    if (rooms.docs.isNotEmpty) {
      throw StateError('Hãy xóa các phòng trước khi xóa homestay.');
    }
    await _homes.doc(id).delete();
  }
}
