import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Login/screens/splash_screen.dart';
import 'Login/screens/loading_screen.dart';
import 'Login/screens/auth_screen.dart';
import 'Home/screens/home_screen.dart';
import 'Login/services/user_service.dart';
import 'Login/services/auth_service.dart';
import 'Core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize UserService
  await UserService().init();

  await AuthService().signOut();

  // Tắt DevicePreview cho production build
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}

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
    _authStateStream = _authService.authStateChanges.map(
      (user) => user != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          debugPrint('Authentication error: ${snapshot.error}');
          return const AuthScreen();
        }

        final isLoggedIn = snapshot.data ?? false;
        return isLoggedIn ? const HomeScreen() : const AuthScreen();
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    final firebaseUser = _authService.currentUser;
    final userServiceLoggedIn = await UserService().isLoggedIn();

    return firebaseUser != null && userServiceLoggedIn;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
