# HealthX Fullstack Platform

Enterprise-grade health & wellness platform featuring a robust Node.js backend API and a cross-platform Flutter mobile application.

This repository is organized as a monorepo:

- **Backend (`/src`)**: Node.js, Express, TypeScript, MongoDB, and Redis.
- **Frontend (`/frontend`)**: Flutter (iOS/Android/Web) using Provider for state management and clean architecture.

---

## 📚 Core Documentation

For detailed guides, please refer to the following documents in the `docs/` folder:

- **[Setup & Run Guide](file:///p:/HealthX/HealthX/docs/SETUP_GUIDE.md)**: Detailed instructions on setting up local databases, installing dependencies, running the backend services, and booting the Flutter mobile application (on Web, Android, or iOS).
- **[Architecture Document](file:///p:/HealthX/HealthX/docs/ARCHITECTURE.md)**: Complete system design, data models, service layers, API endpoint structures, and caching strategies.
- **[Contributing Guidelines](file:///p:/HealthX/HealthX/docs/CONTRIBUTING.md)**: Standards for branch naming, commit formats (Conventional Commits), PR processes, and testing rules.

---

## ⚡ Quick Start

### Prerequisites

Ensure you have the following installed on your system:

- **Node.js**: 20 LTS or higher
- **Flutter SDK**: 3.19+ (with Dart 3.7+)
- **Docker & Docker Compose** (for database and cache containerization)

### 1. Start Database & Cache Services (Docker)

Spin up MongoDB and Redis using Docker Compose from the root directory:

```bash
# Copy template environment file
cp .env.example .env

# Start database services
docker-compose up -d
```

### 2. Start the Backend API Server

From the root directory:

```bash
# Install dependencies
npm install

# Run the development server (with hot-reload)
npm run dev
```

- **Health API Endpoint**: http://localhost:3000/health (Should return `200 OK`)
- **MongoDB Express Admin**: http://localhost:8081 (admin / admin123)
- **Redis Commander**: http://localhost:8082

### 3. Run the Flutter Mobile App

Navigate to the frontend directory:

```bash
cd frontend

# Install dependencies
flutter pub get

# Run on your target device (e.g. Chrome, iOS Simulator, or Android Emulator)
flutter run -d chrome
```

---

## 🧪 Running Tests

### Backend Tests

From the root directory:

```bash
npm test                  # Run unit and integration tests
npm run test:integration  # Run integration tests only
```

### Frontend Tests

From the `frontend/` directory:

```bash
flutter test              # Run unit and widget tests
```

---

## 🐳 Production Deployment

### Docker Deployment

Build and run the production backend container:

```bash
docker build -t healthx-backend:latest .
docker run -p 3000:3000 --env-file .env healthx-backend:latest
```

### Mobile App Releases

Build release binaries for the target platforms:

```bash
cd frontend
flutter build apk --release   # Build Android APK
flutter build ios --release   # Build iOS bundle
flutter build web --release   # Build Web release
```

---

## 🛡️ Security & Compliance

- **Data Privacy**: Input validation using Zod, password hashing via bcrypt, and field-level encryption for sensitive metrics.
- **Access Control**: Role-based access control (RBAC) and JWT authentication (30-minute access, 30-day refresh).
- **Compliance**: HIPAA-compliant design patterns with structured audit logging for all patient database records.
