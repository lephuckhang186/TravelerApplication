import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'Login/screens/splash_screen.dart';
import 'Login/screens/auth_screen.dart';
import 'Home/screens/home_screen.dart';
import 'Login/services/user_service.dart';
import 'Core/theme/app_theme.dart';
import 'Plan/providers/trip_planning_provider.dart';
import 'Expense/providers/expense_provider.dart';
import 'Core/providers/app_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize UserService
  await UserService().init();

  // Enable DevicePreview only in debug mode
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      defaultDevice: Devices.ios.iPhone16ProMax,
      backgroundColor: Colors.black,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TripPlanningProvider()),
        ChangeNotifierProvider(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider(create: (context) => AppModeProvider()),
      ],
      child: MaterialApp(
        title: 'TravelPro - Smart Travel Planner',
        debugShowCheckedModeBanner: false,
        // Enable DevicePreview integration
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
