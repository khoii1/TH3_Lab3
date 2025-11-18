import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Thêm các import Firebase cho tính năng theo dõi + FCM
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'models/restaurant.dart';
import 'models/review.dart';
import 'restaurant_state.dart';
import 'widgets/review_form.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  final String imageAsset;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    required this.imageAsset,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();

    // Nghe danh sách review
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantState>().listenReviews(widget.restaurant.id);
    });

    // Load trạng thái theo dõi nhà hàng
    _loadFollowState();
  }

  Future<void> _loadFollowState() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = userDoc.data();
    final followed =
        (data?['followedRestaurants'] as List<dynamic>?) ?? <dynamic>[];

    if (!mounted) return;
    setState(() {
      _isFollowing = followed.contains(widget.restaurant.id);
    });
  }

  Future<void> _toggleFollow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final restaurantId = widget.restaurant.id;
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final List<dynamic> list =
          (data['followedRestaurants'] as List<dynamic>?)?.toList() ??
          <dynamic>[];

      if (_isFollowing) {
        // Bỏ theo dõi
        list.remove(restaurantId);
        await FirebaseMessaging.instance.unsubscribeFromTopic(
          'restaurant_$restaurantId',
        );
      } else {
        // Theo dõi
        if (!list.contains(restaurantId)) {
          list.add(restaurantId);
        }
        await FirebaseMessaging.instance.subscribeToTopic(
          'restaurant_$restaurantId',
        );
      }

      tx.set(userRef, {'followedRestaurants': list}, SetOptions(merge: true));
    });

    if (!mounted) return;
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantState>(
      builder: (context, state, _) {
        final reviews =
            state.reviewsByRestaurant[widget.restaurant.id] ?? <Review>[];

        return Scaffold(
          appBar: AppBar(title: Text(widget.restaurant.name)),
          // Toàn bộ nội dung cho vào 1 ListView => không bị che
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _buildHeader(context),
                const SizedBox(height: 8),
                if (reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Chưa có đánh giá nào'),
                  )
                else
                  ...reviews.map(_buildReviewTile),
                const SizedBox(height: 8),
                // Form viết đánh giá ở cuối, cũng nằm trong ListView
                ReviewForm(
                  onSubmit:
                      ({
                        required String text,
                        required int rating,
                        File? imageFile,
                      }) async {
                        await state.addReview(
                          restaurantId: widget.restaurant.id,
                          text: text,
                          rating: rating,
                          imageFile: imageFile,
                        );
                      },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final r = widget.restaurant;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh cover từ assets
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.asset(
              widget.imageAsset,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng: thông tin + nút theo dõi
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  r.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                r.avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(' (${r.ratingCount} đánh giá)'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _toggleFollow,
                      icon: Icon(
                        _isFollowing ? Icons.favorite : Icons.favorite_border,
                        color: _isFollowing ? Colors.red : Colors.grey,
                      ),
                      label: Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Giới thiệu',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(r.description, textAlign: TextAlign.justify),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(Review r) {
    return ListTile(
      leading: CircleAvatar(child: Text(r.rating.toString())),
      title: Text(r.userName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r.text),
          if (r.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  r.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
