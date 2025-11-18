import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'restaurant_state.dart';
import 'restaurant_detail_screen.dart';
import 'widgets/restaurant_card.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  // Danh sách ảnh tĩnh trong folder assets
  final List<String> _demoImages = const [
    'assets/images/restaurants/restaurant1.jpg',
    'assets/images/restaurants/restaurant2.jpg',
    'assets/images/restaurants/restaurant3.jpg',
    'assets/images/restaurants/restaurant4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantState>().listenRestaurants();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RestaurantState>(
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Danh sách nhà hàng'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // AuthGate ở main.dart sẽ tự chuyển về màn đăng nhập
                },
              ),
            ],
          ),
          body: state.loadingRestaurants
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: state.restaurants.length,
                  itemBuilder: (context, index) {
                    final r = state.restaurants[index];

                    // Lấy ảnh theo index, xoay vòng nếu ít ảnh
                    final imagePath = _demoImages[index % _demoImages.length];

                    return RestaurantCard(
                      restaurant: r,
                      imageAsset: imagePath,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailScreen(
                              restaurant: r,
                              imageAsset: imagePath, // truyền đường dẫn ảnh
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
