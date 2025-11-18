class Restaurant {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double avgRating;
  final int ratingCount;
  final String description; // mô tả / giới thiệu

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.avgRating,
    required this.ratingCount,
    required this.description,
  });

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    final String name = data['name'] as String? ?? '';

    return Restaurant(
      id: id,
      name: name,
      address: data['address'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0,
      ratingCount: data['ratingCount'] as int? ?? 0,
      // Nếu Firestore chưa có trường description thì dùng câu mô tả mặc định
      description:
          data['description'] as String? ??
          'Nhà hàng $name là địa điểm lý tưởng dành cho những thực khách '
              'yêu thích không gian ấm cúng, món ăn được chuẩn bị kỹ lưỡng và '
              'phong cách phục vụ thân thiện. Đây là dữ liệu mô tả mặc định, '
              'bạn có thể thay bằng nội dung thật trong Firestore.',
    );
  }
}
