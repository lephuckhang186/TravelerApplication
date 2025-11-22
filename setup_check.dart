#!/usr/bin/env dart

// Script kiểm tra cấu hình Firebase và môi trường
import 'dart:io';

void main() async {
  print('🚀 TravelPro - Kiểm Tra Cấu Hình Setup');
  print('=====================================\n');

  bool allGood = true;

  // Kiểm tra Flutter
  print('📱 Kiểm tra Flutter...');
  try {
    final result = await Process.run('flutter', ['--version']);
    if (result.exitCode == 0) {
      print('✅ Flutter đã cài đặt');
      final lines = result.stdout.toString().split('\n');
      if (lines.isNotEmpty) {
        print('   ${lines[0]}');
      }
    } else {
      print('❌ Flutter chưa được cài đặt hoặc không trong PATH');
      allGood = false;
    }
  } catch (e) {
    print('❌ Không thể kiểm tra Flutter: $e');
    allGood = false;
  }

  print('\n📂 Kiểm tra file cấu hình...');

  // Kiểm tra Firebase config files
  final androidConfig = File('android/app/google-services.json');
  if (androidConfig.existsSync()) {
    print('✅ Android google-services.json tồn tại');
  } else {
    print('❌ Thiếu android/app/google-services.json');
    allGood = false;
  }

  final iosConfig = File('ios/Runner/GoogleService-Info.plist');
  if (iosConfig.existsSync()) {
    print('✅ iOS GoogleService-Info.plist tồn tại');
  } else {
    print('❌ Thiếu ios/Runner/GoogleService-Info.plist');
    allGood = false;
  }

  final firebaseOptions = File('lib/firebase_options.dart');
  if (firebaseOptions.existsSync()) {
    print('✅ firebase_options.dart tồn tại');
  } else {
    print('❌ Thiếu lib/firebase_options.dart');
    allGood = false;
  }

  // Kiểm tra pubspec.yaml
  final pubspec = File('pubspec.yaml');
  if (pubspec.existsSync()) {
    final content = await pubspec.readAsString();
    if (content.contains('firebase_core:') && content.contains('firebase_auth:')) {
      print('✅ Firebase dependencies trong pubspec.yaml');
    } else {
      print('❌ Thiếu Firebase dependencies trong pubspec.yaml');
      allGood = false;
    }
  } else {
    print('❌ Không tìm thấy pubspec.yaml');
    allGood = false;
  }

  // Kiểm tra Android build.gradle
  final androidBuildGradle = File('android/build.gradle.kts');
  if (androidBuildGradle.existsSync()) {
    final content = await androidBuildGradle.readAsString();
    if (content.contains('google-services')) {
      print('✅ Google Services plugin trong android/build.gradle.kts');
    } else {
      print('⚠️  Có thể thiếu Google Services plugin trong android/build.gradle.kts');
    }
  }

  print('\n🛠️  Kiểm tra môi trường phát triển...');

  // Kiểm tra Android Studio / SDK
  final androidSdk = Platform.environment['ANDROID_HOME'] ?? 
                    Platform.environment['ANDROID_SDK_ROOT'];
  if (androidSdk != null && Directory(androidSdk).existsSync()) {
    print('✅ Android SDK tìm thấy tại: $androidSdk');
  } else {
    print('⚠️  Android SDK không được cấu hình trong biến môi trường');
  }

  // Kiểm tra Xcode (chỉ trên macOS)
  if (Platform.isMacOS) {
    try {
      final result = await Process.run('xcode-select', ['--print-path']);
      if (result.exitCode == 0) {
        print('✅ Xcode đã cài đặt');
      } else {
        print('⚠️  Xcode chưa được cài đặt hoặc cấu hình');
      }
    } catch (e) {
      print('⚠️  Không thể kiểm tra Xcode');
    }
  }

  // Tóm tắt
  print('\n📊 Kết quả kiểm tra:');
  if (allGood) {
    print('🎉 Tất cả cấu hình cần thiết đã sẵn sàng!');
    print('   Bạn có thể chạy: flutter run');
  } else {
    print('⚠️  Một số cấu hình cần được sửa chữa.');
    print('   Vui lòng xem INSTALLATION_GUIDE.md để biết chi tiết.');
  }

  print('\n🔧 Các lệnh hữu ích:');
  print('   flutter doctor          - Kiểm tra môi trường Flutter');
  print('   flutter pub get         - Cài đặt dependencies');
  print('   flutter clean           - Làm sạch build cache');
  print('   flutter run             - Chạy ứng dụng');
  print('   flutter build apk       - Build APK cho Android');
  print('   flutter build ios       - Build cho iOS');
}