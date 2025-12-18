# TripWise - Ứng Dụng Lập Kế Hoạch Du Lịch Thông Minh

<div align="center">

![TripWise Logo](images/travel.jpg)

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)](https://fastapi.tiangolo.com)
[![LangChain](https://img.shields.io/badge/🦜_LangChain-2E8B57?style=for-the-badge)](https://langchain.com)

*Ứng dụng di động toàn diện với AI Travel Agent thông minh cho việc lập kế hoạch và quản lý chuyến du lịch*

</div>

## 🌟 Tổng Quan

**TripWise** là một hệ sinh thái du lịch thông minh bao gồm:
- **Flutter Mobile App**: Ứng dụng di động đa nền tảng với giao diện hiện đại
- **FastAPI Backend**: API RESTful mạnh mẽ với tích hợp Firebase
- **AI Travel Agent**: Agent AI thông minh sử dụng LangChain và LangGraph

## 🏗️ Kiến Trúc Hệ Thống

```
TripWise/
├── 📱 Mobile App (Flutter)          # Giao diện người dùng
├── 🔧 Backend API (FastAPI)         # Xử lý logic nghiệp vụ  
├── 🤖 AI Travel Agent (LangChain)   # Tư vấn du lịch thông minh
└── 🔥 Firebase Services             # Lưu trữ và xác thực
```

## ✨ Tính Năng Chính

### 🎯 Quản Lý Chuyến Đi
- **Lập Kế Hoạch Thông Minh**: Tạo lịch trình chi tiết với AI assistant
- **Quản Lý Hoạt Động**: Thêm, chỉnh sửa và sắp xếp các hoạt động du lịch
- **Tích Hợp Bản Đồ**: Xem vị trí và điều hướng với Google Maps
- **Chia Sẻ Collaborative**: Mời bạn bè cùng tham gia lập kế hoạch

### 💰 Quản Lý Chi Phí
- **Theo Dõi Chi Tiêu Real-time**: Ghi chép và phân loại chi phí
- **Báo Cáo Tài Chính**: Thống kê chi tiêu theo danh mục và thời gian
- **Đồng Bộ Ngân Sách**: Tích hợp ngân sách với kế hoạch du lịch
- **Chia Sẻ Chi Phí**: Tính toán chi phí nhóm một cách công bằng

### 🛠️ Công Cụ Du Lịch Thông Minh
- **🌍 Dịch Thuật**: Dịch văn bản và OCR hình ảnh đa ngôn ngữ
- **🌤️ Thời Tiết**: Dự báo thời tiết chi tiết cho điểm đến
- **💱 Chuyển Đổi Tiền Tệ**: Tỷ giá hối đoái real-time
- **🕒 Đồng Hồ Thế Giới**: Múi giờ các thành phố trên thế giới

### 🤖 AI Travel Agent (LangChain)
- **Tư Vấn Du Lịch Thông Minh**: Gợi ý địa điểm và hoạt động phù hợp
- **Lập Lịch Trình Tự Động**: Tạo lịch trình chi tiết theo sở thích
- **Tìm Kiếm Khách Sạn**: Gợi ý chỗ nghỉ phù hợp với ngân sách
- **Tính Toán Chi Phí**: Ước tính chi phí chuyến đi chính xác

### 🔔 Thông Báo Thông Minh
- **Nhắc Nhở Hoạt Động**: Thông báo lịch trình sắp tới
- **Cảnh Báo Ngân Sách**: Thông báo khi chi tiêu vượt quá ngân sách
- **Dự Báo Thời Tiết**: Cảnh báo thời tiết bất lợi
- **Thông Báo Cộng Tác**: Cập nhật từ thành viên nhóm

### ⚙️ Cài Đặt & Tài Khoản
- **Xác Thực Firebase**: Đăng nhập Google và email/mật khẩu
- **Quản Lý Hồ Sơ**: Cập nhật thông tin cá nhân và ảnh đại diện
- **Thống Kê Du Lịch**: Xem lịch sử và thống kê chuyến đi
- **Hỗ Trợ Khách Hàng**: Trung tâm trợ giúp và phản hồi

## 🚀 Cài Đặt và Chạy

### Yêu Cầu Hệ Thống
- **Flutter SDK** ≥ 3.9.2
- **Python** ≥ 3.8
- **Node.js** ≥ 16
- **Firebase Project** với các dịch vụ được kích hoạt

### 1. 📱 Flutter Mobile App

```bash
# Clone repository
git clone https://github.com/lephuckhang186/TravelerApplication

# Cài đặt dependencies
flutter pub get

# Cấu hình Firebase
# - Thêm google-services.json vào android/app/
# - Thêm GoogleService-Info.plist vào ios/Runner/

# Chạy ứng dụng
flutter run
```

### 2. 🔧 Backend API (FastAPI)

```bash
# Di chuyển vào thư mục Backend
cd Backend

# Tạo virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# hoặc
venv\Scripts\activate     # Windows

# Cài đặt dependencies
pip install -r requirements.txt

# Cấu hình environment variables
cp .env.example .env
# Chỉnh sửa file .env với API keys của bạn

# Chạy server
python run_server.py
```

### 3. 🤖 AI Travel Agent

```bash
# Di chuyển vào thư mục travel-agent
cd travel-agent

# Cài đặt dependencies
pip install -r requirements.txt

# Cấu hình API keys
cp .env.example .env
# Thêm OPENAI_API_KEY, GOOGLE_API_KEY, TAVILY_API_KEY

# Chạy agent (tích hợp với Backend API)
python main.py
```

## 🔧 Cấu Hình API Keys

Tạo file `.env` trong các thư mục tương ứng:

### Backend/.env
```bash
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."
FIREBASE_CLIENT_EMAIL=your-service-account@project.iam.gserviceaccount.com

# Database
DATABASE_URL=sqlite:///./app.db

# Security
SECRET_KEY=your-secret-key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### travel-agent/.env
```bash
# AI Services
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=AIza...
TAVILY_API_KEY=tvly-...
GEOAPIFY_API_KEY=...

# LangSmith (tùy chọn)
LANGCHAIN_TRACING_V2=true
LANGCHAIN_API_KEY=ls__...
LANGCHAIN_PROJECT=travel-agent
```

## 📊 Kiến Trúc Chi Tiết

### 📱 Flutter App Structure
```
lib/
├── core/                    # Cấu hình và utilities chung
│   ├── config/             # API configuration
│   ├── network/            # HTTP client và exception handling
│   ├── theme/              # App theme và styling
│   └── utils/              # Tiện ích (currency, translation, weather, etc.)
├── Login/                  # Xác thực và quản lý user
├── Home/                   # Màn hình chính
├── Plan/                   # Quản lý kế hoạch du lịch
├── Expense/                # Quản lý chi phí
├── Map/                    # Tích hợp bản đồ
├── Setting/                # Cài đặt ứng dụng
├── smart-notifications/    # Hệ thống thông báo thông minh
└── AltsManager/           # Quản lý alternatives
```

### 🔧 Backend API Structure
```
Backend/
├── app/
│   ├── api/endpoints/      # API routes
│   │   ├── auth.py        # Authentication
│   │   ├── planners.py    # Trip planning
│   │   ├── expenses.py    # Expense management
│   │   ├── activities.py  # Activity management
│   │   └── travel_agent.py # AI agent integration
│   ├── core/              # Core configuration
│   ├── models/            # Data models
│   └── services/          # Business logic
├── db_setup/              # Database setup scripts
└── tests/                 # Unit tests
```

### 🤖 AI Travel Agent Structure
```
travel-agent/
├── services/              # Các dịch vụ AI
│   ├── query_analyzer.py  # Phân tích truy vấn người dùng
│   ├── itinerary.py      # Tạo lịch trình du lịch
│   ├── attractions.py    # Tìm kiếm điểm tham quan
│   ├── hotels.py         # Tìm kiếm khách sạn
│   ├── weather.py        # Dự báo thời tiết
│   └── currency.py       # Chuyển đổi tiền tệ
├── models.py             # Pydantic models
├── workflow.py           # LangGraph workflow
└── main.py              # FastAPI application
```

## 🔥 Tích Hợp Firebase

### Services được sử dụng:
- **Authentication**: Google Sign-in và Email/Password
- **Firestore**: Lưu trữ dữ liệu người dùng và chuyến đi
- **Storage**: Lưu trữ ảnh đại diện và tài liệu
- **Cloud Functions**: Xử lý logic server-side (tùy chọn)

### Firestore Collections:
```
users/                     # Thông tin người dùng
├── profile_data          # Dữ liệu hồ sơ
├── travel_statistics     # Thống kê du lịch
└── preferences           # Tùy chọn cá nhân

trips/                    # Dữ liệu chuyến đi
├── basic_info           # Thông tin cơ bản
├── activities           # Hoạt động và lịch trình
├── expenses             # Chi phí
└── collaborators        # Thành viên nhóm

notifications/           # Thông báo thông minh
├── activity_reminders  # Nhắc nhở hoạt động
├── budget_alerts       # Cảnh báo ngân sách
└── weather_updates     # Cập nhật thời tiết
```

## 🧪 Testing

### Flutter Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/
```

### Backend Tests
```bash
cd Backend
pytest tests/
```

### AI Agent Tests
```bash
cd travel-agent
python -m pytest tests/ -v
```

## 🚀 Deployment

### Mobile App
```bash
# Build for Android
flutter build apk --release

# Build for iOS
flutter build ios --release
```

### Backend API
```bash
# Using Docker
docker build -t tripwise-backend .
docker run -p 8000:8000 tripwise-backend

# Using Railway/Heroku
# Thêm Procfile và deploy
```

### AI Travel Agent
```bash
# Deploy với Backend hoặc standalone
uvicorn main:app --host 0.0.0.0 --port 8001
```
## 📄 License

Dự án này được phân phối dưới MIT License. Xem file `LICENSE` để biết thêm chi tiết.

## 👥 Đội Ngũ Phát Triển

- **Frontend Lead**: Phát triển Flutter app và UI/UX
- **Backend Lead**: Xây dựng FastAPI services và Firebase integration
- **AI Engineer**: Phát triển Travel Agent với LangChain
- **DevOps**: Deployment và infrastructure

## 📞 Liên Hệ

- **Email**: teamtripwise@gmail.com
- **GitHub**: [TripWise Repository](https://github.com/lephuckhang186/TravelerApplication)
- **Documentation**: [Wiki](https://github.com/your-org/tripwise/wiki)

---

<div align="center">

**Được phát triển với ❤️ bởi TripWise Team**

*Biến mỗi chuyến đi thành một trải nghiệm đáng nhớ với sức mạnh của AI*

</div>