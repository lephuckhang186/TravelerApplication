# 🚀 TravelPro App - Hướng dẫn chạy

## 📋 Tình trạng hiện tại:
✅ **Firebase đã được cấu hình hoàn chỉnh cho Web, Android, iOS**
✅ **Auth system hoàn chỉnh với Email/Password + Google Sign-In**
✅ **Assets được cấu hình đúng cho web**
✅ **User data persistence với Firebase**

## 🔧 Cần cài đặt Flutter SDK:

### Windows PowerShell:
```powershell
# Download Flutter SDK
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.5-stable.zip" -OutFile "flutter_sdk.zip"

# Extract
Expand-Archive -Path "flutter_sdk.zip" -DestinationPath "C:\"

# Add to PATH
$env:PATH += ";C:\flutter\bin"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH, [EnvironmentVariable]::Machine)
```

### Hoặc dùng Git:
```bash
git clone https://github.com/flutter/flutter.git -b stable C:\flutter
```

## 🏃‍♂️ Chạy app:
```bash
# Trong thư mục project
flutter doctor
flutter pub get  
flutter run -d chrome
```

## 🎯 App sẽ có:
- Firebase Authentication (Email + Google)
- Responsive design cho web
- Assets images hiển thị đúng
- User data lưu trên Firebase
- Travel planning features

**App đã sẵn sàng chạy ngay khi có Flutter SDK!**