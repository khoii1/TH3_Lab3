import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'models/restaurant.dart';
import 'models/review.dart';

// ĐỔI 2 HẰNG NÀY THEO CLOUDINARY CỦA BẠN
const String cloudinaryCloudName = 'YOUR_CLOUD_NAME';
const String cloudinaryUploadPreset = 'YOUR_UNSIGNED_PRESET';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Restaurant>> streamRestaurants() {
    return _db.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Review>> streamReviews(String restaurantId) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Review.fromFirestore(doc.id, doc.data()))
              .toList();
        });
  }

  // Upload ảnh lên Cloudinary, trả về URL
  Future<String> _uploadToCloudinary(File imageFile) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload ảnh thất bại (${response.statusCode})');
    }

    final body = await response.stream.bytesToString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final imageUrl = data['secure_url'] as String?;
    if (imageUrl == null) {
      throw Exception('Không lấy được secure_url từ Cloudinary');
    }
    return imageUrl;
  }

  Future<void> addReview({
    required String restaurantId,
    required String text,
    required int rating,
    File? imageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }

    // 👉 LUÔN dùng email làm tên hiển thị
    final userName = user.email ?? 'Ẩn danh';

    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _uploadToCloudinary(imageFile);
    }

    final reviewRef = _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reviews')
        .doc();

    await reviewRef.set({
      'userId': user.uid,
      'userName': userName,
      'text': text,
      'rating': rating,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 👉 HÀM MỚI: cập nhật avgRating & ratingCount cho nhà hàng
  Future<void> updateRestaurantRating({
    required String restaurantId,
    required double avgRating,
    required int ratingCount,
  }) async {
    await _db.collection('restaurants').doc(restaurantId).update({
      'avgRating': avgRating,
      'ratingCount': ratingCount,
    });
  }
}
