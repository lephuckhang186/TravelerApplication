# TravelPro Setup Script
# Tự động hóa quá trình setup và cấu hình

Write-Host "🚀 TravelPro - Automated Setup Script" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

# Kiểm tra Flutter
Write-Host "`n📱 Checking Flutter installation..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Flutter not found. Please install Flutter first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Kiểm tra file cấu hình Firebase
Write-Host "`n🔥 Checking Firebase configuration files..." -ForegroundColor Yellow

$androidConfig = "android/app/google-services.json"
$iosConfig = "ios/Runner/GoogleService-Info.plist"

if (Test-Path $androidConfig) {
    Write-Host "✅ Android google-services.json found" -ForegroundColor Green
} else {
    Write-Host "⚠️  Android google-services.json not found" -ForegroundColor Yellow
    Write-Host "   Please download from Firebase Console and place in android/app/" -ForegroundColor Cyan
}

if (Test-Path $iosConfig) {
    Write-Host "✅ iOS GoogleService-Info.plist found" -ForegroundColor Green
} else {
    Write-Host "⚠️  iOS GoogleService-Info.plist not found" -ForegroundColor Yellow
    Write-Host "   Please download from Firebase Console and place in ios/Runner/" -ForegroundColor Cyan
}

# Clean và get dependencies
Write-Host "`n📦 Installing dependencies..." -ForegroundColor Yellow
Write-Host "Running flutter clean..." -ForegroundColor Cyan
flutter clean

Write-Host "Running flutter pub get..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green

# Setup iOS pods (if on macOS or if iOS directory exists)
if (Test-Path "ios") {
    Write-Host "`n🍎 Setting up iOS dependencies..." -ForegroundColor Yellow
    
    if ($IsMacOS -or (Get-Command "pod" -ErrorAction SilentlyContinue)) {
        Push-Location ios
        try {
            Write-Host "Running pod install..." -ForegroundColor Cyan
            pod install
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ iOS pods installed successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠️  Pod install had issues, but continuing..." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️  Could not run pod install. Make sure CocoaPods is installed." -ForegroundColor Yellow
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "⚠️  CocoaPods not found. iOS build may fail." -ForegroundColor Yellow
        Write-Host "   Install CocoaPods: sudo gem install cocoapods" -ForegroundColor Cyan
    }
}

# Kiểm tra devices
Write-Host "`n📱 Checking available devices..." -ForegroundColor Yellow
$devices = flutter devices 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Available devices:" -ForegroundColor Cyan
    Write-Host $devices
} else {
    Write-Host "⚠️  No devices found or flutter devices failed" -ForegroundColor Yellow
}

# Tạo summary
Write-Host "`n📊 Setup Summary" -ForegroundColor Green
Write-Host "=================" -ForegroundColor Green

$configOK = (Test-Path $androidConfig) -and (Test-Path $iosConfig)
$firebaseOptionsOK = Test-Path "lib/firebase_options.dart"

if ($configOK -and $firebaseOptionsOK) {
    Write-Host "🎉 Setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Run: flutter run -d android (for Android)" -ForegroundColor White
    Write-Host "2. Run: flutter run -d ios (for iOS, macOS only)" -ForegroundColor White
    Write-Host "3. Test authentication features" -ForegroundColor White
    Write-Host ""
    Write-Host "📚 For detailed instructions, see:" -ForegroundColor Cyan
    Write-Host "   - INSTALLATION_GUIDE.md" -ForegroundColor White
    Write-Host "   - quick_start.md" -ForegroundColor White
} else {
    Write-Host "⚠️  Setup completed with warnings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Missing items:" -ForegroundColor Red
    
    if (-not (Test-Path $androidConfig)) {
        Write-Host "❌ $androidConfig" -ForegroundColor Red
    }
    if (-not (Test-Path $iosConfig)) {
        Write-Host "❌ $iosConfig" -ForegroundColor Red
    }
    if (-not $firebaseOptionsOK) {
        Write-Host "❌ lib/firebase_options.dart" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Please download Firebase configuration files and place them correctly." -ForegroundColor Cyan
    Write-Host "See INSTALLATION_GUIDE.md for detailed instructions." -ForegroundColor Cyan
}

Write-Host "`n🔧 Useful commands:" -ForegroundColor Yellow
Write-Host "flutter doctor           - Check Flutter environment" -ForegroundColor White
Write-Host "flutter run              - Run the app" -ForegroundColor White
Write-Host "flutter build apk        - Build APK" -ForegroundColor White
Write-Host "flutter logs             - View app logs" -ForegroundColor White
Write-Host "dart setup_check.dart    - Run detailed setup check" -ForegroundColor White

Write-Host "`n✨ Happy coding! ✨" -ForegroundColor Green