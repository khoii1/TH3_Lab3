import 'dart:io';

import 'package:flutter/foundation.dart';

import 'models/restaurant.dart';
import 'models/review.dart';
import 'restaurant_service.dart';

class RestaurantState extends ChangeNotifier {
  final RestaurantService service;

  RestaurantState(this.service);

  bool loadingRestaurants = false;
  List<Restaurant> restaurants = [];

  // reviews theo từng nhà hàng
  Map<String, List<Review>> reviewsByRestaurant = {};
  Map<String, bool> loadingReviews = {};

  String? error;

  // Lắng nghe danh sách nhà hàng (stream realtime)
  void listenRestaurants() {
    loadingRestaurants = true;
    notifyListeners();

    service.streamRestaurants().listen(
      (list) {
        restaurants = list;
        loadingRestaurants = false;
        notifyListeners();
      },
      onError: (e) {
        error = e.toString();
        loadingRestaurants = false;
        notifyListeners();
      },
    );
  }

  // Lắng nghe reviews của 1 nhà hàng và TỰ TÍNH lại sao
  void listenReviews(String restaurantId) {
    loadingReviews[restaurantId] = true;
    notifyListeners();

    service
        .streamReviews(restaurantId)
        .listen(
          (list) async {
            reviewsByRestaurant[restaurantId] = list;
            loadingReviews[restaurantId] = false;

            // TÍNH LẠI ratingCount và avgRating dựa trên list review hiện tại
            final count = list.length;
            double avg = 0;

            if (count > 0) {
              int sum = 0;
              for (final r in list) {
                sum += r.rating;
              }
              avg = sum / count;
            }

            // Cập nhật lại trong mảng restaurants (để UI list dùng)
            final index = restaurants.indexWhere(
              (resto) => resto.id == restaurantId,
            );
            if (index != -1) {
              final old = restaurants[index];
              restaurants[index] = Restaurant(
                id: old.id,
                name: old.name,
                address: old.address,
                imageUrl: old.imageUrl,
                avgRating: avg,
                ratingCount: count,
                description: old.description,
              );
            }

            notifyListeners();

            // Cập nhật ngược lên Firestore để lưu rating chuẩn
            await service.updateRestaurantRating(
              restaurantId: restaurantId,
              avgRating: avg,
              ratingCount: count,
            );
          },
          onError: (e) {
            error = e.toString();
            loadingReviews[restaurantId] = false;
            notifyListeners();
          },
        );
  }

  // Thêm review mới
  Future<void> addReview({
    required String restaurantId,
    required String text,
    required int rating,
    File? imageFile,
  }) async {
    await service.addReview(
      restaurantId: restaurantId,
      text: text,
      rating: rating,
      imageFile: imageFile,
    );
    // Không cần tự tính ở đây, vì streamReviews sẽ bắn lại list mới
  }
}
