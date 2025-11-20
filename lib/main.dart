import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'screens/loading_screen.dart';
import 'services/user_service.dart';
import 'core/theme/app_theme.dart';
// import 'dart:async'; // Tạm thời comment vì không dùng Timer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize UserService
  await UserService().init();
  
  runApp(
    DevicePreview(
      enabled: true, // Bật mô phỏng thiết bị
      builder: (context) => const MyApp(), // App chính của bạn
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyFlow - Smart Finance Tracker',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Use system/default text scaling without overriding
        return DevicePreview.appBuilder(context, child!);
      },
      locale: DevicePreview.locale(context),
      theme: AppTheme.lightTheme,
      home: const LoadingScreen(),
    );
  }

}

