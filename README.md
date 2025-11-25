# TravelPro - Ứng Dụng Lập Lịch Trình Du Lịch Thông Minh

## Thông tin dự án

**Môn học:** Tư duy tính toán
**Chủ đề:** TravelPro - Smart Travel Planning & Expense Management
**Công nghệ:** Flutter Frontend + Python Backend
**Số thành viên:** 4 người  
**Concept:** Kết hợp Notion Timeline + AI Assistant (không hỗ trợ booking)

## Mục tiêu dự án

Xây dựng một ứng dụng lập lịch trình du lịch thông minh với quản lý chi tiêu tích hợp, giúp người dùng:

- **Lập lịch trình du lịch** với timeline tương tác như Notion
- **Quản lý chi tiêu** theo từng chuyến đi với phân tích thông minh  
- **Khám phá địa điểm du lịch** với thông tin chi tiết và đánh giá
- **Chatbot AI** hỗ trợ tối ưu hóa lịch trình và gợi ý địa điểm 24/7
- **Phân tích trải nghiệm** để cải thiện các chuyến đi tương lai

## Core Features - Tính năng chính

### 📅 Trip Planning - Lập Lịch Trình (Core Feature)

#### 🎨 Interactive Timeline Interface

- **Notion-style Timeline:** Advanced drag & drop với visual timeline
- **Multi-view Support:** Day, week, month timeline views
- **Activity Blocks:** Draggable activity cards với color coding
- **Smart Scheduling:** AI đề xuất thời gian tối ưu cho từng hoạt động
- **Conflict Detection:** Auto-detect scheduling conflicts
- **Time Zone Support:** Multi-timezone planning cho international trips

#### 🤝 Real-time Collaboration System

- **Live Collaboration:** Multiple users editing simultaneously
- **User Presence:** See who's online và active cursors
- **Permission Management:** Owner, Editor, Viewer roles
- **Comment & Discussion:** Thread-based comments trên activities
- **Change History:** Complete version control với undo/redo
- **Conflict Resolution:** Smart merge conflict handling
- **Notifications:** Real-time updates về changes và mentions

#### 📚 Smart Templates & Planning

- **Template Library:** Curated collection theo destinations
- **Custom Templates:** Create và share personal templates
- **AI Suggestions:** Intelligent activity recommendations
- **Duplicate Detection:** Avoid duplicate activities
- **Backup Plans:** Alternative options cho weather/availability

#### 🌍 Advanced Integrations

- **Weather Integration:** Real-time weather với activity adjustments
- **Route Optimization:** Multi-stop route planning
- **Local Events:** Discover festivals và seasonal events
- **Transportation:** Public transport schedules integration

### 💰 Expense Management - Quản lý Chi tiêu

- **Budget Planning:** Lập ngân sách chi tiết cho từng chuyến đi
- **Real-time Tracking:** Theo dõi chi tiêu theo thời gian thực
- **Category Analysis:** Phân tích chi tiêu theo danh mục (ăn uống, di chuyển, tham quan)
- **Multi-currency Support:** Hỗ trợ đa tiền tệ với tỷ giá thời gian thực
- **Expense Reports:** Báo cáo chi tiêu trực quan với biểu đồ

### 🎯 Discovery - Khám phá Địa điểm

- **Destination Database:** Cơ sở dữ liệu địa điểm với thông tin chi tiết
- **Smart Recommendations:** AI gợi ý dựa trên sở thích và lịch sử
- **Photo Gallery:** Thư viện ảnh và đánh giá từ cộng đồng
- **Video Content:** YouTube travel videos và destination guides
- **Category Filtering:** Lọc theo loại hình (văn hóa, thiên nhiên, ẩm thực)
- **Local Insights:** Thông tin địa phương và mẹo từ locals
- **Reviews System:** Hệ thống đánh giá và chia sẻ trải nghiệm

### 🤖 AI Assistant - Chatbot Thông minh (Core Feature)

- **24/7 Travel Consultant:** Tư vấn lịch trình và địa điểm mọi lúc
- **Itinerary Optimization:** Phân tích và đề xuất cải thiện lịch trình
- **Budget Advisor:** Tư vấn tối ưu chi phí cho từng hoạt động
- **Real-time Adjustments:** Điều chỉnh kế hoạch theo thời tiết/tình况
- **Local Knowledge:** Chia sẻ thông tin địa phương và văn hóa
- **Personalized Tips:** Gợi ý cá nhân hóa dựa trên sở thích

## Tech Stack - Công nghệ sử dụng

### 📱 Frontend (Flutter)

- **Framework:** Flutter 3.x
- **State Management:** Provider/Riverpod cho reactive state
- **UI/UX:** Material Design 3 + Custom timeline components
- **Navigation:** Go Router cho navigation
- **Local Storage:** SQLite cho offline data
- **Maps:** Google Maps SDK cho location services
- **HTTP:** Dio cho API calls tới Python backend

### 🐍 Backend (Python)

- **Framework:** FastAPI cho REST APIs
- **Database:** PostgreSQL cho production data
- **Cache:** Redis cho caching và session management
- **AI/ML:**
  - OpenAI GPT-4 cho chatbot
  - scikit-learn cho recommendation engine
  - NLTK cho text processing
- **Maps:** Google Places API, OpenStreetMap
- **Weather:** OpenWeatherMap API
- **Deployment:** Docker + Railway/Heroku

### 🔧 Development Tools

- **Frontend IDE:** VS Code với Flutter extensions
- **Backend IDE:** PyCharm/VS Code
- **Version Control:** Git & GitHub
- **API Testing:** Postman/Thunder Client
- **Design:** Figma cho UI/UX prototypes
- **Database:** pgAdmin cho PostgreSQL management

## Cấu trúc Project

### Frontend Structure (Flutter)

```text
TravelerApplication/
├── lib/
│   ├── core/                           # Core utilities & config
│   │   ├── constants/                  # App constants, API endpoints
│   │   ├── utils/                      # Helper functions, extensions
│   │   ├── services/                   # API services, HTTP client
│   │   ├── theme/                      # App theme, colors, typography
│   │   └── config/                     # Environment config
│   ├── shared/                         # Shared components
│   │   ├── models/                     # Data models (Trip, Place, User)
│   │   ├── widgets/                    # Reusable widgets
│   │   ├── providers/                  # Global state providers
│   │   └── utils/                      # Shared utilities
│   ├── features/                       # Feature modules
│   │   ├── auth/                       # Authentication
│   │   │   ├── models/
│   │   │   ├── services/
│   │   │   ├── providers/
│   │   │   └── screens/
│   │   ├── trip_planning/              # Lập lịch trình (Core)
│   │   │   ├── models/                 # Trip, Activity, Timeline models
│   │   │   ├── services/               # Trip API services, WebSocket
│   │   │   ├── providers/              # Advanced state management
│   │   │   ├── widgets/                # Timeline components
│   │   │   │   ├── timeline/           # Core timeline widgets
│   │   │   │   ├── drag_drop/          # Drag & drop system
│   │   │   │   ├── collaboration/      # Real-time collaboration UI
│   │   │   │   └── templates/          # Template widgets
│   │   │   ├── screens/                # Trip screens
│   │   │   │   ├── trip_list/          # Trip listing
│   │   │   │   ├── trip_editor/        # Main timeline editor
│   │   │   │   ├── collaboration/      # Collaboration management
│   │   │   │   └── templates/          # Template browser
│   │   │   └── utils/                  # Timeline utilities
│   │   ├── collaboration/              # Real-time collaboration (Quân)
│   │   │   ├── models/                 # Collaboration models
│   │   │   ├── services/               # WebSocket services
│   │   │   ├── providers/              # Real-time state management
│   │   │   └── widgets/                # Collaboration widgets
│   │   ├── discovery/                  # Khám phá địa điểm
│   │   │   ├── models/                 # Place, Review models
│   │   │   ├── services/               # Discovery API services
│   │   │   ├── providers/              # Discovery state
│   │   │   ├── widgets/                # Place cards, filters
│   │   │   └── screens/                # Discovery screens
│   │   ├── ai_assistant/               # Chatbot
│   │   │   ├── models/                 # Chat, Message models
│   │   │   ├── services/               # Chat API services
│   │   │   ├── providers/              # Chat state
│   │   │   ├── widgets/                # Chat bubble, input widgets
│   │   │   └── screens/                # Chat screens
│   │   ├── expense_tracking/           # Quản lý chi tiêu (Basic)
│   │   │   ├── models/
│   │   │   ├── services/
│   │   │   ├── providers/
│   │   │   └── screens/
│   │   └── home/                       # Dashboard
│   │       ├── models/
│   │       ├── services/
│   │       ├── providers/
│   │       └── screens/
│   └── main.dart
└── assets/                             # Design assets

### Backend Structure (Python)
```text
travelpro-backend/
├── app/
│   ├── core/                           # Core utilities
│   │   ├── config.py                   # App configuration
│   │   ├── database.py                 # Database connection
│   │   ├── security.py                 # Authentication utilities
│   │   └── exceptions.py               # Custom exceptions
│   ├── models/                         # Database models
│   │   ├── user.py
│   │   ├── trip.py
│   │   ├── place.py
│   │   ├── activity.py
│   │   └── chat.py
│   ├── api/                            # API routes
│   │   ├── endpoints/
│   │   │   ├── auth.py
│   │   │   ├── trips.py                # Trip CRUD operations
│   │   │   ├── places.py               # Place discovery APIs
│   │   │   ├── chat.py                 # Chatbot APIs
│   │   │   ├── expenses.py             # Basic expense APIs
│   │   │   └── collaboration.py        # Collaboration APIs 
│   │   └── deps.py                     # Dependencies
│   ├── services/                       # Business logic
│   │   ├── ai_service.py               # OpenAI integration
│   │   ├── recommendation_service.py   # ML recommendations
│   │   ├── maps_service.py             # Google Maps integration
│   │   ├── weather_service.py          # Weather APIs
│   │   ├── trip_optimizer.py           # Route optimization
│   │   ├── websocket_service.py        # Real-time collaboration 
│   │   ├── template_service.py         # Template management
│   │   ├── notification_service.py     # Push notifications
│   │   └── youtube_service.py          # YouTube API integration (Thuận)
│   └── main.py                         # FastAPI app
├── alembic/                            # Database migrations
├── tests/
├── requirements.txt
└── docker-compose.yml
```

## Team Assignment - Phân chia công việc

### 👨‍💼 Dương Anh Kiệt: Backend Lead & AI Assistant Feature

**Backend modules phụ trách:**

- `app/core/` - Core backend architecture (Lead)
- `app/models/` - Database models design (Lead)
- `app/services/ai_service.py` - OpenAI chatbot integration
- `app/api/endpoints/chat.py` - Chat APIs
- `app/api/endpoints/auth.py` - Authentication APIs

**Frontend modules phụ trách:**

- `lib/features/ai_assistant/` - Complete AI Assistant feature
- `lib/core/services/` - API client setup (Lead)

**Nhiệm vụ chính:**

- Lead backend architecture với FastAPI + PostgreSQL
- Implement complete AI Assistant feature (backend + frontend)
- Design và manage toàn bộ database schema
- Authentication system (login, register, JWT)
- Backend deployment và DevOps

### 💰 Lê Phúc Khang: Expense Management & Analytics Feature

**Backend modules phụ trách:**

- `app/api/endpoints/expenses.py` - Complete Expense APIs
- `app/services/analytics_service.py` - Advanced data analytics
- `app/services/currency_service.py` - Multi-currency support

**Frontend modules phụ trách:**

- `lib/features/expense_tracking/` - Complete expense management
- `lib/features/home/` - Dashboard với expense analytics
- `lib/shared/widgets/` - Charts và visualization components

**Nhiệm vụ chính:**

- Complete Expense Management feature (backend + frontend)
- Advanced analytics và reporting system
- Multi-currency support với real-time exchange rates
- Budget planning và spending insights
- Export functionality (PDF, Excel)

### 📅 Nguyễn Kiều Anh Quân: Frontend Lead & Trip Planning Feature

**Frontend modules phụ trách:**

- `lib/core/theme/` - Complete design system (Lead)
- `lib/shared/widgets/` - UI component library (Lead)
- `assets/` - Icons, illustrations, animations (Lead)
- `lib/features/trip_planning/` - Complete Trip Planning feature
- `lib/features/collaboration/` - Real-time collaboration system
- Cross-module UI consistency (Lead)

**Backend modules phụ trách:**

- `app/api/endpoints/trips.py` - Trip management APIs
- `app/api/endpoints/collaboration.py` - Collaboration APIs
- `app/services/websocket_service.py` - Real-time collaboration

**Nhiệm vụ chính:**

- Lead frontend architecture và design system
- Complete Trip Planning feature (Notion-style timeline)
- Real-time collaboration system (WebSocket)
- Advanced UI components và animations
- Mobile-responsive design với 60fps performance

### 🎯 Nguyễn Dương Gia Thuận: Discovery & Maps Feature

**Backend modules phụ trách:**

- `app/api/endpoints/places.py` - Complete Places APIs
- `app/services/recommendation_service.py` - AI recommendation engine
- `app/services/maps_service.py` - Google Maps integration
- `app/services/weather_service.py` - Weather integration
- `app/services/youtube_service.py` - YouTube API integration

**Frontend modules phụ trách:**

- `lib/features/discovery/` - Complete discovery system
- `lib/features/auth/` - Authentication UI screens

**Nhiệm vụ chính:**

- Complete Discovery & Maps feature (backend + frontend)
- AI-powered recommendation engine
- Google Places API và Maps integration
- Weather API integration cho trip planning
- YouTube API integration cho travel videos và guides
- Reviews, ratings và photo gallery system

## Development Timeline - 8 weeks

### Phase 1: Foundation Setup (Weeks 1-2)

| Member | Backend Tasks | Frontend Tasks |
|--------|---------------|----------------|
| **Kiệt (Backend Lead)** | FastAPI architecture, DB schema, Auth APIs | API client setup, AI Assistant wireframes |
| **Khang** | Expense APIs foundation | Expense UI mockups, dashboard design |
| **Quân (Frontend Lead)** | Trip APIs foundation | **Complete Design System**, component library |
| **Thuận** | Places APIs, Google Maps setup | Discovery UI mockups, auth screens |

### Phase 2: Core Features (Weeks 3-5)

| Member | Backend Tasks | Frontend Tasks |
|--------|---------------|----------------|
| **Kiệt** | **Complete AI Assistant backend**, OpenAI integration | **Complete AI Assistant UI**, chat interface |
| **Khang** | **Complete Expense APIs**, analytics engine | **Complete Expense Management**, dashboard charts |
| **Quân** | Trip APIs, collaboration backend | **Advanced Timeline System**, drag & drop interface |
| **Thuận** | **Complete Places APIs**, recommendation ML | **Complete Discovery System**, search & filters |

### Phase 3: Integration & Advanced Features (Weeks 6-7)

| Member | Backend Tasks | Frontend Tasks |
|--------|---------------|----------------|
| **Kiệt** | AI trip optimization, chatbot training | Advanced chatbot features, voice input |
| **Khang** | Multi-currency APIs, export services | Advanced analytics, export functionality |
| **Quân** | **Real-time collaboration**, WebSocket | **Live Collaboration UI**, user presence |
| **Thuận** | Weather APIs, YouTube API, reviews system | Maps integration, video content, photo gallery |

### Phase 4: Polish & Testing (Week 8)

- Integration testing between frontend/backend
- Performance optimization
- UI/UX refinements
- Bug fixes và stability
- Demo preparation

## API Endpoints Design

### Authentication APIs

```
POST /api/auth/register
POST /api/auth/login  
POST /api/auth/refresh
GET /api/auth/profile
```

### Trip Planning APIs (Core)

```
# Basic Trip Management
GET /api/trips                    # User's trips
POST /api/trips                   # Create trip
GET /api/trips/{trip_id}         # Trip details
PUT /api/trips/{trip_id}         # Update trip
DELETE /api/trips/{trip_id}      # Delete trip

# Activity Management
POST /api/trips/{trip_id}/activities  # Add activity
PUT /api/activities/{activity_id}     # Update activity
DELETE /api/activities/{activity_id}  # Delete activity
POST /api/activities/batch            # Batch operations
POST /api/trips/{trip_id}/optimize    # AI optimize route

# Collaboration APIs (Quân's specialty)
POST /api/trips/{trip_id}/collaborators     # Add collaborator
DELETE /api/trips/{trip_id}/collaborators/{user_id}  # Remove collaborator
GET /api/trips/{trip_id}/collaborators      # List collaborators
PUT /api/trips/{trip_id}/permissions        # Update permissions
GET /api/trips/{trip_id}/activity-feed      # Get activity feed
POST /api/trips/{trip_id}/comments          # Add comment
GET /api/activities/{activity_id}/comments  # Get comments

# Template System
GET /api/templates                    # Public templates
POST /api/templates                   # Create template
GET /api/templates/{template_id}      # Template details
POST /api/trips/{trip_id}/apply-template  # Apply template
GET /api/users/templates              # User's templates

# Real-time Collaboration
WS /api/trips/{trip_id}/live          # WebSocket for real-time sync
POST /api/trips/{trip_id}/presence    # Update user presence
GET /api/trips/{trip_id}/conflicts    # Get merge conflicts
POST /api/trips/{trip_id}/resolve     # Resolve conflicts
```

### Discovery APIs

```
GET /api/places/search           # Search places
GET /api/places/{place_id}       # Place details
GET /api/places/recommendations  # AI recommendations
POST /api/places/{place_id}/reviews  # Add review
GET /api/places/categories       # Place categories
```

### Chatbot APIs (Core)

```
POST /api/chat/message           # Send message
GET /api/chat/history           # Chat history
POST /api/chat/trip-advice      # Trip-specific advice
POST /api/chat/optimize-itinerary # Itinerary optimization
```

### Expense APIs (Basic)

```
GET /api/expenses               # User expenses
POST /api/expenses             # Add expense
PUT /api/expenses/{expense_id} # Update expense  
DELETE /api/expenses/{expense_id} # Delete expense
GET /api/expenses/analytics    # Expense analytics
```

## Development Setup

### 🚀 Hướng dẫn chạy dự án (Quick Start)

#### Bước 1: Clone repository

```bash
git clone https://github.com/lephuckhang186/TravelerApplication.git
cd TravelerApplication
```

#### Bước 2: Setup Backend (Python FastAPI)

```bash
# 1. Di chuyển vào thư mục Backend
cd Backend

# 2. Tạo virtual environment
python -m venv venv
# Windows PowerShell:
venv\Scripts\Activate.ps1
# Windows CMD:
venv\Scripts\activate.bat
# macOS/Linux:
source venv/bin/activate

# 3. Cài đặt dependencies
pip install -r requirements.txt

# 4. Thiết lập Firebase (cần thiết)
# Tạo file firebase-service-account.json trong thư mục Backend/
# Tải từ Firebase Console -> Project Settings -> Service Accounts

# 5. Thiết lập biến môi trường
# Tạo file .env trong Backend/ với nội dung:
echo 'FIREBASE_SERVICE_ACCOUNT_PATH="./firebase-service-account.json"' > .env

# 6. Chạy server
python run_server.py
# Hoặc:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Server sẽ chạy tại: http://localhost:8000
# API Documentation: http://localhost:8000/docs
```

#### Bước 3: Setup Frontend (Flutter)

```bash
# 1. Di chuyển về thư mục root
cd ..

# 2. Kiểm tra Flutter đã được cài đặt
flutter doctor

# 3. Cài đặt dependencies
flutter pub get

# 4. Chạy ứng dụng Flutter
flutter run

# Hoặc chạy trên emulator/device cụ thể:
flutter run -d chrome        # Web browser
flutter run -d android      # Android emulator
flutter run -d ios          # iOS simulator
```

#### Bước 4: Kiểm tra kết nối

```bash
# Test API backend
curl http://localhost:8000/health

# Kết quả mong đợi:
# {"status": "healthy", "message": "TravelPro Backend API", ...}
```

### 🛠️ Troubleshooting thường gặp

#### Backend Issues

```bash
# Lỗi Firebase credentials:
# 1. Đảm bảo firebase-service-account.json tồn tại
# 2. Kiểm tra đường dẫn trong .env file
# 3. Kiểm tra quyền file

# Lỗi import modules:
# 1. Đảm bảo đang trong virtual environment: venv\Scripts\activate
# 2. Cài lại dependencies: pip install -r requirements.txt
# 3. Kiểm tra Python version: python --version (cần >= 3.8)

# Lỗi port đã được sử dụng:
# Thay đổi port: uvicorn app.main:app --port 8001
```

#### Frontend Issues

```bash
# Lỗi Flutter dependencies:
flutter clean
flutter pub get

# Lỗi kết nối API:
# Kiểm tra baseUrl trong lib/core/config/api_config.dart
# Đảm bảo backend đang chạy trên đúng port

# Lỗi build:
flutter clean
flutter pub get
flutter run --debug
```

### Backend Setup (Chi tiết)

```bash
# 1. Clone và setup backend
git clone https://github.com/lephuckhang186/TravelerApplication.git
cd TravelerApplication/Backend

# 2. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Setup environment variables
cp .env.example .env
# Cập nhật DATABASE_URL, FIREBASE_SERVICE_ACCOUNT_PATH, etc.

# 5. Setup database (nếu sử dụng)
# alembic upgrade head

# 6. Run development server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend Setup (Chi tiết)

```bash
# 1. Setup Flutter project
cd TravelerApplication
flutter pub get

# 2. Configure API endpoints
# Cập nhật base URL trong lib/core/config/api_config.dart

# 3. Run Flutter app
flutter run
```

### Environment Variables

#### Backend (.env)

```bash
DATABASE_URL=postgresql://user:password@localhost/travelpro_db
REDIS_URL=redis://localhost:6379
OPENAI_API_KEY=your_openai_api_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
WEATHER_API_KEY=your_weather_api_key
YOUTUBE_API_KEY=your_youtube_api_key
SECRET_KEY=your_jwt_secret_key
```

#### Frontend (API Constants)

```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8000/api';
  static const String chatEndpoint = '/chat';
  static const String tripsEndpoint = '/trips';
  static const String placesEndpoint = '/places';
}
```

## Git Workflow

### Branch Strategy

```bash
main                    # Production
└── develop            # Development integration
    ├── backend/        # Backend development
    │   ├── feature/chat-api     # Kiệt
    │   └── feature/places-api   # Thuận
    └── frontend/       # Frontend development
        ├── feature/timeline-ui   # Quân
        └── feature/expense-ui    # Khang
```

### Daily Workflow

```bash
# 1. Lấy code mới nhất
git checkout develop
git pull origin develop

# 2. Tạo/chuyển sang feature branch
git checkout -b feature/your-feature-name

# 3. Commit thường xuyên
git add .
git commit -m "feat: add trip planning timeline"

# 4. Push và tạo Pull Request
git push origin feature/your-feature-name
# Tạo PR trên GitHub, assign reviewer
```

## Testing Strategy

### Backend Testing (Python)

```bash
# Unit tests
pytest tests/unit/

# Integration tests
pytest tests/integration/

# API tests
pytest tests/api/

# Test coverage
pytest --cov=app
```

### Frontend Testing (Flutter)

```bash
# Unit tests
flutter test test/unit/

# Widget tests  
flutter test test/widget/

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
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

## Database Schema Design

### Core Tables

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    preferences JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trips table (Core)
CREATE TABLE trips (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    destination VARCHAR(255),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10,2),
    currency VARCHAR(3),
    is_collaborative BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Places table
CREATE TABLE places (
    id SERIAL PRIMARY KEY,
    google_place_id VARCHAR(255) UNIQUE,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    category VARCHAR(100),
    rating DECIMAL(2,1),
    photo_urls TEXT[],
    description TEXT
);

-- Activities table (Core - Timeline items)
CREATE TABLE activities (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER REFERENCES trips(id),
    place_id INTEGER REFERENCES places(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    estimated_cost DECIMAL(10,2),
    notes TEXT,
    order_index INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Expenses table (Basic)
CREATE TABLE expenses (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER REFERENCES trips(id),
    user_id INTEGER REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3),
    category VARCHAR(50),
    date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Chat messages (AI Assistant)
CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    trip_id INTEGER REFERENCES trips(id),
    message TEXT NOT NULL,
    is_from_user BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trip Collaborators (Quân's collaboration system)
CREATE TABLE trip_collaborators (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER REFERENCES trips(id),
    user_id INTEGER REFERENCES users(id),
    role VARCHAR(20) DEFAULT 'viewer', -- owner, editor, viewer
    invited_by INTEGER REFERENCES users(id),
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(trip_id, user_id)
);

-- Activity Comments
CREATE TABLE activity_comments (
    id SERIAL PRIMARY KEY,
    activity_id INTEGER REFERENCES activities(id),
    user_id INTEGER REFERENCES users(id),
    comment TEXT NOT NULL,
    parent_comment_id INTEGER REFERENCES activity_comments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trip Templates
CREATE TABLE trip_templates (
    id SERIAL PRIMARY KEY,
    created_by INTEGER REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    destination VARCHAR(255),
    duration_days INTEGER,
    category VARCHAR(100),
    is_public BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    rating DECIMAL(2,1) DEFAULT 0,
    template_data JSONB, -- Serialized timeline structure
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Real-time Presence (for collaboration)
CREATE TABLE user_presence (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER REFERENCES trips(id),
    user_id INTEGER REFERENCES users(id),
    cursor_position JSONB,
    selected_activity_id INTEGER,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(trip_id, user_id)
);

-- Change History (for version control)
CREATE TABLE trip_changes (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER REFERENCES trips(id),
    user_id INTEGER REFERENCES users(id),
    change_type VARCHAR(50), -- create, update, delete, move
    entity_type VARCHAR(50), -- trip, activity, comment
    entity_id INTEGER,
    old_data JSONB,
    new_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Activity Mentions (for notifications)
CREATE TABLE activity_mentions (
    id SERIAL PRIMARY KEY,
    comment_id INTEGER REFERENCES activity_comments(id),
    mentioned_user_id INTEGER REFERENCES users(id),
    mentioned_by INTEGER REFERENCES users(id),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## External APIs Integration

### 🗺️ Maps & Location

- **Google Maps:** Places, Directions, Geocoding
- **OpenStreetMap:** Alternative mapping solution
- **Foursquare:** Venue data và reviews

### 🎥 Video Content

- **YouTube Data API:** Travel videos và destination guides
- **Video Recommendations:** AI-curated travel content
- **Local Creator Content:** Discover local travel creators

### 🌦️ Weather & Context

- **OpenWeatherMap:** Weather forecasts
- **Time Zone DB:** Local time information

### 🤖 AI & ML Services

- **OpenAI GPT-4:** Chatbot conversation
- **Google Cloud AI:** Text analysis
- **Custom ML Models:** Recommendation engine

### 💰 Financial Services

- **ExchangeRate-API:** Real-time currency conversion
- **Fixer.io:** Alternative currency API

## Success Metrics - Chỉ tiêu thành công

### 🎥 Demo Deliverables

1. **Functional MVP:** Core timeline planning + expense tracking
2. **AI Chatbot:** Working assistant với contextual responses
3. **Backend APIs:** Full REST API với Python FastAPI
4. **UI/UX Showcase:** Notion-style timeline với smooth interactions
5. **Live Demo:** Real-time trip planning và collaborative editing

### 📈 Performance Targets

- **API Response:** < 2 seconds average
- **App Launch:** < 3 seconds on mobile
- **Offline Capability:** Core features work without internet
- **Cross-platform:** Consistent experience iOS/Android
- **Team Velocity:** 0% merge conflicts, 100% parallel development

### 📊 Technical Achievements

- **Backend:** Scalable FastAPI + PostgreSQL + Redis architecture
- **AI Integration:** OpenAI GPT-4 với contextual trip advice
- **Advanced UI/UX:** Notion-level timeline complexity với Flutter
- **Real-time Collaboration:** WebSocket-powered live editing với user presence
- **Mobile Performance:** 60fps timeline animations với complex interactions
- **Design System:** Comprehensive Material Design 3 implementation
- **Accessibility:** WCAG 2.1 compliant collaborative interface
- **Conflict Resolution:** Smart merge system cho concurrent editing
- **Cross-platform:** Consistent experience across all devices
- **Data Analytics:** Expense insights và trip optimization

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
