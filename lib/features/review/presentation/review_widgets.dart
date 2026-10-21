import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/review.dart';

class ReviewScore extends StatelessWidget {
  const ReviewScore(this.reviews, {super.key});
  final List<StayReview> reviews;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const Text(
        'Chưa có đánh giá sau lưu trú',
        style: TextStyle(fontSize: 12, color: muted),
      );
    }
    final score =
        reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: brand, size: 19),
        const SizedBox(width: 3),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Text(
          ' (${reviews.length} đánh giá)',
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ],
    );
  }
}

class ReviewList extends StatelessWidget {
  const ReviewList(this.reviews, {super.key});
  final List<StayReview> reviews;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final review in reviews)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      child: Icon(Icons.person_outline, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review.guestName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${review.rating}/5',
                      style: const TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: brand, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(review.comment),
              ],
            ),
          ),
        ),
    ],
  );
}
