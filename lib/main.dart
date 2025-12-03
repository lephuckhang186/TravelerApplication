import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'Login/screens/splash_screen.dart';
import 'Login/screens/loading_screen.dart';
import 'Login/screens/auth_screen.dart';
import 'Home/screens/home_screen.dart';
import 'Login/services/user_service.dart';
import 'Login/services/auth_service.dart';
import 'Plan/providers/trip_planning_provider.dart';
import 'Expense/providers/expense_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize UserService
  await UserService().init();

  // Enable DevicePreview only in debug mode
  runApp(
    DevicePreview(enabled: !kReleaseMode, builder: (context) => const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TripPlanningProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: MaterialApp(
        title: 'TravelPro - Smart Travel Planner',
        debugShowCheckedModeBanner: false,
        // Tắt DevicePreview cho production
        // builder: (context, child) => DevicePreview.appBuilder(context, child!),
        // locale: DevicePreview.locale(context),
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
          '/loading': (context) => const LoadingScreen(),
        },
      ),
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
    _authStateStream = _authService.authStateChanges.map(
      (user) => user != null,
    );
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
