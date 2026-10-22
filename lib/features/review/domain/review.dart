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
