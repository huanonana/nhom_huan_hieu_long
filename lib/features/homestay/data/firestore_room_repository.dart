import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/catalog.dart';

class FirestoreRoomRepository {
  FirestoreRoomRepository(this._firestore);

  final FirebaseFirestore _firestore;
  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('rooms');

  Stream<List<Room>> watchAll() => _rooms.snapshots().map(
    (snapshot) => snapshot.docs
        .map((doc) => Room.fromFirestore(doc.data(), id: doc.id))
        .toList(growable: false),
  );

  Stream<List<Room>> watchByHomestay(String homestayId) => _rooms
      .where('homestayId', isEqualTo: homestayId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => Room.fromFirestore(doc.data(), id: doc.id))
            .toList(growable: false),
      );

  Future<Room?> get(String id) async {
    final snapshot = await _rooms.doc(id).get();
    return snapshot.exists
        ? Room.fromFirestore(snapshot.data()!, id: snapshot.id)
        : null;
  }

  Future<void> save(Room room) =>
      _rooms.doc(room.id).set(room.toFirestore(), SetOptions(merge: true));

  Future<void> delete(String id) => _rooms.doc(id).delete();
}
