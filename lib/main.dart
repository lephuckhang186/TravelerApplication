import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'Login/screens/splash_screen.dart';
import 'Login/screens/auth_screen.dart';
import 'Home/screens/home_screen.dart';
import 'Login/services/user_service.dart';
import 'Core/theme/app_theme.dart';
import 'Plan/providers/trip_planning_provider.dart';
import 'Plan/providers/collaboration_provider.dart';
import 'Expense/providers/expense_provider.dart';
import 'smart-nofications/providers/smart_notification_provider.dart';
import 'Core/providers/app_mode_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

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

/// The root widget of the TripWise application.
///
/// Configures high-level app state, including theme, routes, and global providers.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Start real-time listeners immediately when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRealTimeListeners();
    });
  }

  Future<void> _startRealTimeListeners() async {
    try {
      // Access providers to start listeners
      final context = this.context;
      if (context.mounted) {
        final collaborationProvider = context.read<CollaborationProvider>();

        // Only start listeners if user is authenticated
        final user = await FirebaseAuth.instance.authStateChanges().first;
        if (user != null) {
          await collaborationProvider.ensureInitialized();
        } else {
          //
        }
      }
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TripPlanningProvider()),
        ChangeNotifierProvider(create: (context) => CollaborationProvider()),
        ChangeNotifierProvider(create: (context) => ExpenseProvider()),
        ChangeNotifierProvider(
          create: (context) => SmartNotificationProvider(),
        ),
        ChangeNotifierProvider(create: (context) => AppModeProvider()),
      ],
      child: MaterialApp(
        title: 'TripWise - Smart Travel Planner',
        debugShowCheckedModeBanner: false,
        // Enable DevicePreview integration
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
