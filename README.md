# Smart Tourism System - Du Lịch Thông Minh

## Thông tin dự án

**Môn học:** Tư duy tính toán
**Chủ đề:** Smart Tourism System (Hệ thống Du lịch Thông minh)  
**Công nghệ:** Flutter Framework  
**Số thành viên:** 4 người  

## Mục tiêu dự án

Xây dựng một ứng dụng di động thông minh hỗ trợ du khách trong suốt hành trình du lịch, từ lên kế hoạch đến trải nghiệm thực tế. Ứng dụng tích hợp AI để cung cấp các đề xuất cá nhân hóa về:
- Lộ trình du lịch tối ưu
- Nhà hàng và món ăn địa phương  
- Khách sạn phù hợp ngân sách
- Điểm tham quan theo sở thích
- Phương tiện di chuyển

## Tính năng chính

### Giai đoạn lập kế hoạch (Before Trip)
- **Đề xuất lộ trình:** Tối ưu hóa hành trình nhiều ngày dựa trên thuật toán
- **Gợi ý điểm đến:** Phân loại theo sở thích (văn hóa, thiên nhiên, mua sắm)
- **Lựa chọn chỗ ở:** Đề xuất khách sạn/homestay phù hợp ngân sách
- **Chatbot thông minh:** Hỗ trợ tư vấn và lập kế hoạch hợp lý

### Giai đoạn sau chuyến đi (After Trip)
- **Phân tích đánh giá:** Sentiment analysis để xếp hạng địa điểm
- **Đề xuất chuyến đi tiếp theo:** Dựa trên lịch sử và sở thích

## Công nghệ sử dụng

### Frontend (Flutter)
- **Framework:** Flutter 3.x
- **State Management:** Provider / Riverpod
- **UI Components:** Material Design 3
- **Maps Integration:** OpenStreetMap Plugin

### Backend & AI Integration  
- **APIs:** OpenStreetMap, Places
- **Machine Learning:** TensorFlow Lite cho mobile
- **NLP Services:** Translates API
- **Recommendation Engine:** Custom algorithm + collaborative filtering
- **Database:** Firebase Firestore
- **Authentication:** Firebase Auth

### Công cụ phát triển
- **IDE:** Android Studio / VS Code
- **Version Control:** Git & GitHub
- **Design:** Figma cho UI/UX mockups  
- **Testing:** Flutter Test Framework

## Cấu trúc thư mục

```
TravelerApplication/
├── lib/
│   ├── core/                    # Core utilities, constants
│   │   ├── constants/
│   │   ├── utils/
│   │   └── services/
│   ├── data/                    # Data layer
│   │   ├── models/
│   │   ├── repositories/
│   │   └── datasources/
│   ├── domain/                  # Business logic
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── presentation/            # UI layer  
│   │   ├── pages/
│   │   ├── widgets/
│   │   ├── providers/
│   │   └── themes/
│   ├── features/                # Feature modules
│   │   ├── trip_planning/
│   │   ├── recommendation/
│   │   ├── navigation/
│   │   ├── chatbot/
│   │   └── photo_recognition/
│   └── main.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/
├── android/
├── ios/
└── pubspec.yaml
```

## Phân chia công việc

### Dương Anh Kiệt: Project Leader & Trip Planning
- Quản lý dự án tổng thể  
- Phát triển module lập kế hoạch du lịch
- Thuật toán tối ưu hóa lộ trình
- Tích hợp Google Maps API

### Lê Phúc Khang: Recommendation System & AI Integration
- Xây dựng hệ thống đề xuất thông minh
- Tích hợp machine learning models  
- Phát triển recommendation engine
- API integration cho AI services

### Nguyễn Kiều Anh Quân và Nguyễn Dương Gia Thuận: UI/UX & Frontend Development  
- Thiết kế giao diện người dùng
- Implement responsive design
- Phát triển components tái sử dụng
- State management implementation

### Member 4: Backend & Data Management
- Firebase setup và configuration
- Database design và optimization  
- Authentication system
- API development và documentation

## Timeline thực hiện

| Tuần | Nhiệm vụ | Deliverables |
|------|----------|--------------|
| 1-2 | **Phân tích vấn đề & Thiết kế** | Requirements document, System design |
| 3-4 | **Decomposition & Pattern Recognition** | Feature breakdown, UI mockups |
| 5 | **Algorithm Design** | Pseudocode, Flowcharts |
| 6-7 | **Implementation Phase 1** | Core features, Basic UI |
| 8-9 | **Implementation Phase 2** | AI integration, Testing |
| 10-11 | **Finalization** | Bug fixes, Report, Presentation |

## Cài đặt và chạy ứng dụng

### Yêu cầu hệ thống
- Flutter SDK >= 3.0.0
- Dart >= 2.17.0
- Android Studio / Xcode
- Firebase project setup

### Các bước cài đặt

1. **Clone repository**
```bash
git clone https://github.com/lephuckhang186/TravelerApplication
cd TravelerApplication
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Cấu hình Firebase**
```bash
# Thêm google-services.json (Android) và GoogleService-Info.plist (iOS)
# Cấu hình Firebase trong firebase_options.dart
```

4. **Chạy ứng dụng**
```bash
flutter run
```

## Testing

```bash
# Unit tests
flutter test

# Integration tests  
flutter test integration_test

# Widget tests
flutter test test/widget_test.dart
```

## Computational Thinking Application

### 1. Problem Analysis (Phân tích vấn đề)
- **Input:** Sở thích, ngân sách, thời gian, vị trí GPS
- **Output:** Danh sách đề xuất được cá nhân hóa
- **Context:** Giải quyết vấn đề du lịch thiếu thông tin và cá nhân hóa

### 2. Decomposition (Phân rã vấn đề)
- Module lập kế hoạch du lịch
- Hệ thống đề xuất thông minh  
- Giao diện người dùng
- Tích hợp AI và xử lý dữ liệu

### 3. Pattern Recognition (Nhận dạng mẫu)
- Phân tích hành vi người dùng
- Clustering địa điểm theo loại hình
- Pattern matching cho recommendation

### 4. Abstraction (Trừu tượng hóa)
- User preferences model
- Location và rating abstraction  
- API service abstraction layer

### 5. Algorithm Design (Thiết kế thuật toán)
- Collaborative filtering cho recommendation
- Dijkstra/A* cho route optimization
- NLP processing cho chatbot

## Performance Metrics

- **Accuracy:** Độ chính xác của recommendation > 80%
- **Response Time:** API response < 2s
- **User Experience:** App loading time < 3s  
- **Offline Support:** Core features hoạt động offline

## APIs và Data Sources

### External APIs
- **Google Maps Platform:** Places, Directions, Geocoding
- **OpenWeatherMap:** Thông tin thời tiết
- **Firebase:** Authentication, Database, Storage

### Datasets  
- **Kaggle:** Tourism, restaurant datasets
- **Vietnam Tourism Data:** VNAT official data
- **User Generated Content:** Reviews, ratings, photos

## Expected Outcomes

1. **Ứng dụng mobile hoạt động:** Flutter app với core features
2. **AI Integration:** Recommendation system với machine learning
3. **User Testing:** Feedback từ 10+ users thực tế
4. **Documentation:** Complete technical documentation
5. **Presentation:** Demo và presentation cuối kỳ

## Liên hệ

- **Team Lead:** Dương Anh Kiệt - 0958167330
- **GitHub:** https://github.com/lephuckhang186/TravelerApplication

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*Dự án được thực hiện trong khuôn khổ môn CTT009 - Computational Thinking, Trường Đại học Khoa học Tự nhiên, ĐHQG-HCM*