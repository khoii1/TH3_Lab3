import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userName;
  final String text;
  final int rating;
  final String? imageUrl;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userName,
    required this.text,
    required this.rating,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Review.fromFirestore(String id, Map<String, dynamic> data) {
    final rawName = (data['userName'] as String?) ?? '';
    final userName = rawName.trim().isEmpty ? 'Ẩn danh' : rawName;

    return Review(
      id: id,
      userName: userName,
      text: data['text'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
