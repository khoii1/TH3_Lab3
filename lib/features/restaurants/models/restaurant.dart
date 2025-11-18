class Restaurant {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double avgRating;
  final int ratingCount;
  final String description;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.avgRating,
    required this.ratingCount,
    required this.description,
  });

  // 👉 Topic FCM dùng cho nhà hàng này
  String get fcmTopic => 'restaurant_$id';

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    final String name = data['name'] as String? ?? '';

    return Restaurant(
      id: id,
      name: name,
      address: data['address'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0,
      ratingCount: data['ratingCount'] as int? ?? 0,
      description:
          data['description'] as String? ??
          'Nhà hàng $name là địa điểm lý tưởng dành cho những thực khách '
              'yêu thích không gian ấm cúng, món ăn được chuẩn bị kỹ lưỡng và '
              'phong cách phục vụ thân thiện. Đây là dữ liệu mô tả mặc định, '
              'bạn có thể thay bằng nội dung thật trong Firestore.',
    );
  }
}
