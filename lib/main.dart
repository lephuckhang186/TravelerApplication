import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/loading_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/user_service.dart';
import 'services/auth_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize UserService
  await UserService().init();
  
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelPro - Smart Travel Planner',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return DevicePreview.appBuilder(context, child!);
      },
      locale: DevicePreview.locale(context),
      theme: AppTheme.lightTheme,
      home: const LoadingScreen(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/loading': (context) => const LoadingScreen(),
      },
    );
  }
}

// Widget để kiểm tra trạng thái authentication
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  late final Stream<bool> _authStateStream;

  @override
  void initState() {
    super.initState();
    // Tạo stream một lần để tránh rebuild không cần thiết
    _authStateStream = _authService.authStateChanges.map((user) => user != null);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // Hiển thị loading screen khi đang kết nối
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // Kiểm tra lỗi
        if (snapshot.hasError) {
          // Có thể thêm ErrorScreen ở đây hoặc fallback về AuthScreen
          debugPrint('Authentication error: ${snapshot.error}');
          return const AuthScreen();
        }

        // Điều hướng dựa trên trạng thái đăng nhập
        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const HomeScreen() : const AuthScreen();
      },
    );
  }

  @override
  void dispose() {
    // Đảm bảo cleanup nếu cần
    super.dispose();
  }
}