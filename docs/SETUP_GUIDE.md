# HealthX Setup & Execution Guide

This document provides step-by-step instructions for setting up and running the HealthX backend and frontend applications.

---

## 📋 Prerequisites

Before starting, ensure you have the following installed on your system:

### Core Requirements

- **Node.js**: 20.x LTS or higher ([download](https://nodejs.org/))
- **npm**: 10.x or higher
- **Docker & Docker Compose**: 20.10+ ([download](https://www.docker.com/products/docker-desktop))
- **Git**: 2.x or higher

### Frontend Requirements (Flutter)

- **Flutter SDK**: 3.19+ ([download](https://flutter.dev/docs/get-started/install))
- **Dart SDK**: (Bundled automatically with Flutter)
- **Platform SDKs** (Optional, based on target platform):
  - **Android**: Android Studio & Android SDK (for Android Emulators)
  - **iOS**: Xcode (macOS only, for iOS Simulators)
  - **Web**: Chrome or any modern web browser (Easiest setup, no mobile SDKs needed)

### Verify Installations

Ensure your environment is set up correctly by running:

```bash
node --version
npm --version
docker --version
docker-compose --version
flutter doctor
```

---

## 🚀 Backend Setup & Run

### 1. Copy Environment Variables

Create a local environment configuration file in the project root:

```bash
cp .env.example .env
```

_For local development, the default configurations in the `.env.example` template are pre-configured to connect to local Docker-managed services._

### 2. Run Database & Cache Services (Docker)

Start the MongoDB database and Redis cache containers:

```bash
docker-compose up -d
```

This command starts:

- **MongoDB** at `mongodb://localhost:27017`
- **Redis** at `redis://localhost:6379`
- **Mongo Express Admin Console** at http://localhost:8081 (admin / admin123)
- **Redis Commander** at http://localhost:8082

### 3. Install Backend Dependencies & Start Server

From the root directory:

```bash
# Install npm dependencies
npm install

# Start the dev server with hot-reload (nodemon)
npm run dev
```

### 4. Verify Backend Health

Once running, check the health API endpoint:

- http://localhost:3000/health
- Expected response: `{"status":"ok","database":"connected"}`

---

## 📱 Frontend Setup & Run

The Flutter mobile application is located in the root `frontend/` directory.

### 1. Install Dependencies

Navigate to the frontend folder and fetch the Dart dependencies:

```bash
cd frontend
flutter pub get
```

### 2. Launch the Application

#### Option A: Web Browser (Easiest)

Run the application inside Google Chrome (no emulator required):

```bash
flutter run -d chrome
```

#### Option B: Android Emulator

1. Start your Android Emulator (either via Android Studio's AVD Manager or command line):
   ```bash
   # List available Android Virtual Devices
   emulator -list-avds
   # Start emulator
   emulator -avd <your_device_name>
   ```
2. Run the app:
   ```bash
   flutter devices   # Verify emulator is recognized
   flutter run       # Boots on the active emulator
   ```

#### Option C: iOS Simulator (macOS Only)

1. Launch the iOS Simulator:
   ```bash
   open -a Simulator
   ```
2. Run the app:
   ```bash
   flutter run
   ```

---

## 🧪 Running Tests

### 1. Backend Testing

From the project root directory:

```bash
npm test                  # Run unit and integration tests
npm run test:watch        # Watch mode for hot-reloading tests
npm run test:integration  # Integration tests only
npm test -- --coverage    # Show test coverage details
```

### 2. Frontend Testing

From the `frontend/` directory:

```bash
flutter test              # Run unit and widget tests
flutter test --coverage   # Generate coverage reports
```

---

## 🐳 Production Server Build

To run the backend server in production mode locally or inside a container:

### Standard Build

```bash
npm run build
npm start
```

### Docker Release Build

```bash
docker build -t healthx-backend:latest .
docker run -p 3000:3000 --env-file .env healthx-backend:latest
```

---

## 🔧 Troubleshooting

### "Port 3000 already in use"

Find and terminate the process holding port 3000:

- **Windows (PowerShell)**:
  ```powershell
  Get-NetTCPConnection -LocalPort 3000 | Select-Object -ExpandProperty OwningProcess | ForEach-Object { Stop-Process -Id $_ -Force }
  ```
- **macOS/Linux**:
  ```bash
  kill -9 $(lsof -t -i:3000)
  ```

### MongoDB/Redis Connection Failures

- Ensure Docker is running and verify active containers: `docker ps`.
- Restart database containers: `docker-compose restart`.
- Verify that your `.env` contains the correct connection strings (`MONGODB_URI` and `REDIS_URL`).

### "npm ERR! code ERESOLVE"

Clear the cache and perform a clean installation:

```bash
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```
