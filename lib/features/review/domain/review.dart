import 'package:cloud_firestore/cloud_firestore.dart';

class StayReview {
  const StayReview({
    required this.bookingId,
    required this.homestayId,
    required this.guestId,
    required this.guestName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String bookingId, homestayId, guestId, guestName, comment;
  final int rating;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'bookingId': bookingId,
    'homestayId': homestayId,
    'guestId': guestId,
    'guestName': guestName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toFirestore() => {
    'bookingId': bookingId,
    'homestayId': homestayId,
    'guestId': guestId,
    'guestName': guestName,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory StayReview.fromFirestore(Map<String, dynamic> data) {
    final rawDate = data['createdAt'];
    final createdAt = switch (rawDate) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      String value =>
        DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0),
      _ => DateTime.fromMillisecondsSinceEpoch(0),
    };
    return StayReview(
      bookingId: data['bookingId'] as String? ?? '',
      homestayId: data['homestayId'] as String? ?? '',
      guestId: data['guestId'] as String? ?? '',
      guestName: data['guestName'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  factory StayReview.fromJson(Map<String, dynamic> json) => StayReview(
    bookingId: json['bookingId'] as String,
    homestayId: json['homestayId'] as String,
    guestId: json['guestId'] as String,
    guestName: json['guestName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
