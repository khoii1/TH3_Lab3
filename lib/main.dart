import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';

import 'features/auth/auth_service.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/auth_screen.dart';

import 'features/restaurants/restaurant_service.dart';
import 'features/restaurants/restaurant_state.dart';
import 'features/restaurants/restaurant_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nếu bạn đã có google-services.json cho Android,
  // dùng initializeApp() đơn giản như này là được:
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider(create: (_) => AuthState(AuthService())),
        // Restaurants
        ChangeNotifierProvider(
          create: (_) => RestaurantState(RestaurantService()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // Chưa đăng nhập -> màn Auth có Consumer<AuthState>
          return const AuthScreen();
        }

        // Đã đăng nhập -> màn danh sách nhà hàng
        return const RestaurantListScreen();
      },
    );
  }
}
