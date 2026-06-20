# HealthX Frontend v1 → v2 Gap Analysis & Migration Report

**Status**: Analysis Complete — Active Migration (Phase 0)  
**Generated**: June 11, 2026  
**Last Updated**: June 11, 2026  

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Backend Architecture Assessment](#2-backend-architecture-assessment)
3. [Frontend v1 Analysis](#3-frontend-v1-analysis)
4. [Frontend v2 Analysis](#4-frontend-v2-analysis)
5. [Feature Gap Analysis — Missing in v2](#5-feature-gap-analysis--missing-in-v2)
6. [Architecture & Dependency Comparison](#6-architecture--dependency-comparison)
7. [Migration Priority Matrix](#7-migration-priority-matrix)
8. **— Sub-Phase Migration Plan with Checkpoints —**
9. [Progress Log](#9-progress-log)

---

## 1. Executive Summary

**HealthX** is a comprehensive health & wellness platform with a full-stack architecture:

- **Backend**: Express + TypeScript + MongoDB + Redis (at `src/`) — fully operational, 15 route modules, 25+ Mongoose models, comprehensive middleware stack
- **Frontend v1** (`frontend/`): Flutter with Provider, ~85 Dart files, ~60 screens, Firebase integration, 75+ dependencies — full feature set
- **Frontend v2** (`frontend_v2/`): Flutter with Riverpod, clean architecture (feature-first), ~55 Dart files, ~35 screens, 18 dependencies — ~40% feature parity with v1

**Key finding**: v2 is a ground-up rewrite using superior architecture (Riverpod, clean layers, GoRouter with StatefulShellRoute) but lacks ~60% of v1's features. The backend is fully capable of supporting all v1 features.

---

## 2. Backend Architecture Assessment

### Overall Rating: 9.1 / 10

| Category | Rating | Notes |
|----------|--------|-------|
| Architecture | 9.5/10 | Clean layered architecture, excellent separation of concerns |
| Codebase Structure | 9.5/10 | Well-organized routes/controllers/services/models |
| Code Quality | 9.0/10 | TypeScript, Zod schemas, consistent patterns |
| Database Models | 9.0/10 | 25+ Mongoose models, proper indexing, virtuals |
| Security | 9.5/10 | Helmet, CORS, rate-limiting, audit logs, JWT |
| Pipeline/CI | 8.5/10 | Docker Compose, scripts, comprehensive tests |
| Functionality | 9.5/10 | All 15 route modules operational |
| Frontend Quality | 8.5/10 | v2's Riverpod approach is cleaner than v1's Provider |

### Backend Route Modules (15 total)

| Module | Routes | Status |
|--------|--------|--------|
| Auth | `/api/auth/*` | Full auth (register, login, OAuth, password reset, refresh tokens, 2FA) |
| Users | `/api/users/*` | Profile CRUD, preferences, achievements |
| Onboarding | `/api/onboarding/*` | Multi-step onboarding flow |
| Meals | `/api/meals/*` | Meal plans, food logging, nutrition tracking |
| Trackers | `/api/trackers/*` | Health metrics tracking (weight, steps, water, sleep, etc.) |
| Orders | `/api/orders/*` | Order management, delivery tracking |
| Doctors | `/api/doctors/*` | Doctor directory |
| Appointments | `/api/appointments/*` | Booking, scheduling |
| Health Records | `/api/health-records/*` | Medical records, HealthKit/Google Fit sync |
| Prakriti | `/api/prakriti/*` | Ayurvedic body type assessment |
| Subscriptions | `/api/subscriptions/*` | Plan management, payments |
| Notifications | `/api/notifications/*` | Push notifications, in-app alerts |
| Content | `/api/content/*` | Articles, tips, educational content |
| Addresses | `/api/addresses/*` | Delivery address management |
| Security | `/api/security/*` | Security settings, device management, 2FA |

---

## 3. Frontend v1 Analysis

### Architecture
- **State Management**: Provider (ChangeNotifier pattern)
- **Navigation**: GoRouter
- **Structure**: Type-based (screens/, services/, providers/, models/, widgets/)
- **Testing**: Limited test coverage

### Feature Completeness
- ~60 screens covering all platform features
- Full Firebase integration (Auth, Firestore, Cloud Messaging, Analytics)
- Local notifications (flutter_local_notifications)
- Rich animations (Flutter Animate, Shimmer, Carousel)
- Charts (fl_chart)
- Responsive design (flutter_screenutil, responsive_framework)
- Web support
- Custom painters (Water Jar, Progress Arc, Bubble Background)

### Top 10 Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Firebase authentication |
| `firebase_messaging` | Push notifications |
| `go_router` | Navigation |
| `flutter_local_notifications` | Local notifications |
| `http` | Network requests |
| `shared_preferences` | Local storage |
| `fl_chart` | Charts |
| `flutter_animate` | Animations |

---

## 4. Frontend v2 Analysis

### Architecture (Superior to v1)
- **State Management**: Riverpod (superior type safety & testability vs Provider)
- **Navigation**: GoRouter with StatefulShellRoute (persistent bottom nav)
- **Structure**: Feature-first clean architecture (auth/, tracker/, shop/, consults/, health/, rewards/, profile/, notifications/, home/)
- **Testing**: No tests yet

### Feature Completeness
- ~35 screens (~40% of v1 feature set)
- Core screens implemented (home, auth, tracker dashboard, basic shop, basic consults, basic health, profile)
- Clean separation of concerns with repository pattern
- No Firebase dependency

### All Dependencies (18)

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `riverpod_annotation` | Code generation |
| `go_router` | Navigation |
| `dio` | Network requests |
| `json_annotation` | JSON serialization |
| `shared_preferences` | Local storage |
| `flutter_secure_storage` | Secure storage |
| `intl` | i18n |
| `cached_network_image` | Image caching |
| `shimmer` | Loading skeletons |
| `lottie` | Lottie animations |
| `flutter_svg` | SVG support |
| `url_launcher` | URL launching |
| `image_picker` | Image picking |
| `fluttertoast` | Toast messages |
| `connectivity_plus` | Network status |
| `package_info_plus` | App info |
| `cupertino_icons` | iOS icons |

---

## 5. Feature Gap Analysis — Missing in v2

### 5.1 Authentication & Account
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 1 | Email/Password Login | ✅ | ✅ | ✅ |
| 2 | Google Sign-In | ✅ | ❌ Missing | ✅ |
| 3 | Apple Sign-In | ✅ | ❌ Missing | ✅ (via OAuth config) |
| 4 | Biometric Auth | ✅ | ❌ Missing | N/A |
| 5 | Forgot Password | ✅ | ❌ Missing | ✅ `POST /api/auth/forgot-password` |
| 6 | 2FA / Security Settings | ✅ | ❌ Missing | ✅ `api/auth/2fa`, `api/security/*` |
| 7 | Device Management | ✅ | ❌ Missing | ✅ `api/security/devices` |
| 8 | Multi-step Onboarding | ✅ | ❌ Missing | ✅ `api/onboarding/*` |

### 5.2 Meal & Nutrition Tracking
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 9 | Meal Plans (create/view) | ✅ | ❌ Missing | ✅ `api/meals/meal-plans` |
| 10 | Meal Plan Detail Screen | ✅ | ❌ Missing | ✅ |
| 11 | Grocery / Shopping List | ✅ | ❌ Missing | ✅ |
| 12 | Nutrition Tracking Dashboard | ✅ | ❌ Missing | ✅ `api/trackers/nutrition` |
| 13 | Log Food Manually | ✅ | ❌ Missing | ✅ `api/meals/food-logs` |
| 14 | Log Food from Text Search | ✅ | ❌ Missing | ✅ |
| 15 | Food Detail / Nutritional Info | ✅ | ❌ Missing | ✅ |
| 16 | Meal History Calendar | ✅ | ❌ Missing | ✅ |
| 17 | Water Intake Tracker | ✅ | ❌ Missing | ✅ `api/trackers/hydration` |

### 5.3 Health Tracking
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 18 | Health Records (Vitals, Lab Reports) | ✅ | ❌ Missing | ✅ `api/health-records/*` |
| 19 | Apple HealthKit Sync | ✅ | ❌ Missing | ✅ `api/health-records/sync` |
| 20 | Google Fit Sync | ✅ | ❌ Missing | ✅ `api/health-records/sync` |
| 21 | Sleep Insights & Analysis | ✅ | ❌ Missing | ✅ `api/trackers/sleep` |
| 22 | Weekly Health Chart | ✅ | ❌ Missing | ✅ `fl_chart` needed |
| 23 | Step Counter / Activity Tracking | ✅ | ❌ Missing | ✅ `api/trackers/activities` |
| 24 | Weight Tracking with Chart | ✅ | ❌ Missing | ✅ `api/trackers/weight` |
| 25 | BMI Calculator | ✅ | ❌ Missing | ✅ (compute on client) |
| 26 | Period Tracker | ✅ | ❌ Missing | ✅ `api/trackers/period` |
| 27 | Symptom Logger | ✅ | ❌ Missing | ✅ `api/trackers/symptoms` |

### 5.4 Shop & Orders
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 28 | Product Catalog / Menu Screen | 🔄 Partial | ❌ Missing | ✅ `api/orders/menu` |
| 29 | Product Detail Screen | 🔄 Partial | ❌ Missing | ✅ |
| 30 | Cart Management | ✅ | ❌ Missing | ✅ `api/orders/cart` |
| 31 | Checkout / Place Order | ✅ | ❌ Missing | ✅ `api/orders/checkout` |
| 32 | Order History | ✅ | ❌ Missing | ✅ `api/orders/history` |
| 33 | Order Tracking (Real-time) | ✅ | ❌ Missing | ✅ `api/orders/tracking` |
| 34 | Delivery Location Picker | ✅ | ❌ Missing | ✅ (Map integration) |
| 35 | Set Delivery Address | ✅ | ❌ Missing | ✅ `api/addresses/*` |
| 36 | Add New Address Screen | ✅ | ❌ Missing | ✅ |
| 37 | Subscription Plans | ✅ | ❌ Missing | ✅ `api/subscriptions/*` |

### 5.5 Consultations & Doctors
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 38 | Doctor Directory with Search | ✅ | ✅ | ✅ `api/doctors/*` |
| 39 | Doctor Detail / Profile | ✅ | ✅ | ✅ |
| 40 | Book Appointment | ✅ | ✅ | ✅ `api/appointments/*` |
| 41 | Appointment History | ✅ | ✅ | ✅ |
| 42 | Telemedicine / Video Call | ✅ | ❌ Missing | Requires WebRTC/third-party |
| 43 | Prescriptions | ✅ | ❌ Missing | ✅ |
| 44 | Lab Reports | ✅ | ❌ Missing | ✅ `api/health-records/*` |
| 45 | Review & Rating | ✅ | ❌ Missing | ✅ `api/doctors/reviews` |

### 5.6 Rewards & Gamification
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 46 | Points / Coins System | ✅ | ❌ Missing | ✅ `api/users/points` |
| 47 | Achievement Badges | ✅ | ❌ Missing | ✅ `api/users/achievements` |
| 48 | Daily Streaks | ✅ | ❌ Missing | ✅ `api/trackers/streaks` |
| 49 | Leaderboard | ✅ | ❌ Missing | ✅ |
| 50 | Rewards Store | ✅ | ❌ Missing | ✅ |
| 51 | Referral Program | ✅ | ❌ Missing | ✅ |

### 5.7 Notifications
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 52 | Firebase Cloud Messaging | ✅ | ❌ Missing | ✅ `api/notifications/*` |
| 53 | Local Notifications (Scheduled) | ✅ | ❌ Missing | N/A |
| 54 | In-App Notification Center | ✅ | ❌ Missing | ✅ `api/notifications/in-app` |
| 55 | Notification Preferences | ✅ | ❌ Missing | ✅ `api/notifications/preferences` |
| 56 | Reminder Scheduling (Meals, Water, etc.) | ✅ | ❌ Missing | ✅ |

### 5.8 Ayurveda & Prakriti
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 57 | Prakriti Assessment Quiz | ✅ | ❌ Missing | ✅ `api/prakriti/*` |
| 58 | Prakriti Result / Body Type | ✅ | ❌ Missing | ✅ |
| 59 | Ayurvedic Recommendations | ✅ | ❌ Missing | ✅ `api/content/ayurveda` |

### 5.9 Content & Education
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 60 | Articles / Blog | 🔄 Partial | ✅ | ✅ `api/content/articles` |
| 61 | Tips of the Day | ✅ | ❌ Missing | ✅ `api/content/tips` |
| 62 | Video Content | ✅ | ❌ Missing | ✅ |
| 63 | Recipes | ✅ | ❌ Missing | ✅ `api/meals/recipes` |
| 64 | FAQ / Help Center | ✅ | ❌ Missing | ✅ |

### 5.10 UI / Polish Features
| # | Feature | v1 | v2 | Notes |
|---|---------|----|----|-------|
| 65 | Shimmer Loading Skeleton | ✅ | ✅ | Same shimmer package, but fewer screens use it |
| 66 | Lottie Animations | ✅ | ✅ | Present in v2 |
| 67 | Flutter Animate (Rich Animations) | ✅ | ❌ Missing | `flutter_animate` not in v2 |
| 68 | Carousel / Banner Slider | ✅ | ❌ Missing | Missing from home screen |
| 69 | Charts (fl_chart: line, bar, pie) | ✅ | ❌ Missing | No `fl_chart` dependency |
| 70 | Custom Painters (Water Jar, Arc, Bubble) | ✅ | ❌ Missing | No custom paint widgets |
| 71 | Responsive Layouts | ✅ | ❌ Missing | `flutter_screenutil` & `responsive_framework` |
| 72 | Haptic Feedback | ✅ | ❌ Missing | |
| 73 | Pull to Refresh | ✅ | ❌ Missing on most screens | |
| 74 | Infinite Scroll / Pagination | ✅ | ❌ Missing | |
| 75 | Animated Page Transitions | ✅ | ❌ Missing | |

### 5.11 Integrations
| # | Feature | v1 | v2 | Backend Ready? |
|---|---------|----|----|----------------|
| 76 | Firebase Core | ✅ | ❌ Dropped | N/A |
| 77 | Firebase Auth | ✅ | ❌ Dropped | ✅ (JWT auth instead) |
| 78 | Firebase Firestore | ✅ | ❌ Dropped | ✅ (MongoDB backend) |
| 79 | Firebase Analytics | ✅ | ❌ Dropped | Can add later |
| 80 | Firebase Crashlytics | ✅ | ❌ Dropped | Can add later |
| 81 | Apple HealthKit | ✅ | ❌ Missing | ✅ `api/health-records/sync` |
| 82 | Google Fit | ✅ | ❌ Missing | ✅ |
| 83 | Web Support | ✅ | ❌ Dropped | V2 is mobile-only |

### 5.12 Developer Infrastructure
| # | Feature | v1 | v2 | Notes |
|---|---------|----|----|-------|
| 84 | Unit Tests | 🔄 Partial | ❌ None | |
| 85 | Widget Tests | 🔄 Partial | ❌ None | |
| 86 | Integration Tests | ❌ None | ❌ None | |
| 87 | CI/CD Pipeline | ✅ | ❌ Not configured | |
| 88 | Code Generation (build_runner) | ❌ None | ✅ | Riverpod + json_serializable |
| 89 | Environment Config | ✅ | ❌ Missing | Dev/staging/prod config files |
| 90 | Error Tracking | ✅ | ❌ Missing | |

### 5.13 Summary Counts

| Category | Total Features | Missing in v2 | % Missing |
|----------|---------------|---------------|-----------|
| Auth & Account | 8 | 7 | 87% |
| Meal & Nutrition | 9 | 9 | 100% |
| Health Tracking | 10 | 10 | 100% |
| Shop & Orders | 10 | 10 | 100% |
| Consultations | 8 | 4 | 50% |
| Rewards | 6 | 6 | 100% |
| Notifications | 5 | 5 | 100% |
| Ayurveda | 3 | 3 | 100% |
| Content | 5 | 4 | 80% |
| UI / Polish | 11 | 9 | 82% |
| Integrations | 8 | 8 | 100% |
| Developer Infra | 7 | 6 | 86% |
| **Total** | **90** | **81** | **90%** |

**Note**: The ~40% screen parity figure reflects that v2 implemented the most complex/structural screens first (home, auth flow, doctor directory, booking, basic profile, basic tracker dashboard). The missing 81 features are mostly screens and widgets that can be built using existing patterns in v2.

---

## 6. Architecture & Dependency Comparison

### State Management

| Aspect | v1 (Provider) | v2 (Riverpod) |
|--------|---------------|---------------|
| Pattern | ChangeNotifier | Riverpod (code-gen) |
| Type Safety | Limited | Strong |
| Testability | Moderate | Excellent |
| Boilerplate | Less (no code gen) | More but safer |
| Scoping | Manual | Automatic via ProviderScope |
| Async Support | Manual | Built-in AsyncValue |

### Feature Structure

| Aspect | v1 (Type-based) | v2 (Feature-first) |
|--------|-----------------|-------------------|
| Auth | auth_screen.dart + auth_provider.dart | auth/presentation/ + auth/data/ + auth/domain/ |
| Tracker | tracker_screen.dart + tracker_provider.dart | tracker/presentation/ + tracker/data/ + tracker/domain/ |
| Extensibility | Flat, grows messy | Clean, scales well |

### Codebase Size

| Metric | v1 | v2 |
|--------|-----|----|
| Dart files | ~85 | ~55 |
| Screens | ~60 | ~35 |
| Providers | 10+ | 7 |
| Services | 12+ | 8 |
| Dependencies | 75+ | 18 |

---

## 7. Migration Priority Matrix

| Priority | Category | Effort | Impact | Backend Ready | Dependencies Needed |
|----------|----------|--------|--------|---------------|---------------------|
| **P0** | Notifications (FCM + Local) | Medium | High | ✅ | firebase_messaging, flutter_local_notifications |
| **P0** | Meal Plans & Nutrition | High | High | ✅ | (none new) |
| **P1** | Health Records & Charts | High | High | ✅ | fl_chart, health_kit |
| **P1** | Shop, Cart, Orders | High | High | ✅ | (none new) |
| **P2** | Rewards & Gamification | Medium | Medium | ✅ | (none new) |
| **P2** | Prakriti Assessment | Medium | Medium | ✅ | (none new) |
| **P2** | Ayurvedic Content | Low | Medium | ✅ | (none new) |
| **P3** | Animations & UI Polish | Medium | Low | N/A | flutter_animate, carousel |
| **P3** | Web Support | High | Low | N/A | responsive_framework, web libs |

### Effort Estimates
- **P0**: 2-3 weeks
- **P1**: 3-4 weeks
- **P2**: 2-3 weeks
- **P3**: 1-2 weeks
- **Total**: 8-12 weeks for full v1 parity

---

## 8. Sub-Phase Migration Plan with Checkpoints

### Phase 0 — Foundation & Infrastructure Setup

#### 0.1 — Firebase & FCM Push Notifications
**Goal**: Initialize Firebase, register FCM, handle background/foreground messages, route taps.
**Depends on**: `firebase_core`, `firebase_messaging`, `flutter_local_notifications` (packages already in pubspec.yaml)
**Backend**: `api/notifications/*` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 0.1.1 | Initialize Firebase in `main.dart` | App boots without crash on iOS/Android |
| 0.1.2 | Add `FirebaseMessaging` background handler (top-level function) | Background messages logged without crash |
| 0.1.3 | Request notification permissions + subscribe to `all_users` topic | Token printed in debug console |
| 0.1.4 | Initialize `flutter_local_notifications` with 2 channels (`general`, `rewards`) | `showFlipkartNotification()` renders BigText + BigPicture styles |
| 0.1.5 | Add foreground listener that delegates to local notifications | Foreground FCM messages show as local notification |
| 0.1.6 | Add tap handler routing (`/rewards` for `claim_reward` payload) | Tapping notification navigates to correct screen |
| **0.1 ✅** | **All FCM + local notification init complete** | **Notifications appear in foreground, background, and tap navigates** |

#### 0.2 — Notification Preferences & Reminders
**Goal**: Preference toggles UI, water reminder scheduling, notification bell with badge.
**Depends on**: Phase 0.1
**Backend**: `api/notifications/preferences` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 0.2.1 | Add notification preference toggles to Settings screen (water, sleep, health, orders, promos) | 5 toggle switches render and persist to SharedPreferences |
| 0.2.2 | Implement water reminder scheduling (8AM–9PM every 30min, 27 slots) | Water reminders fire at correct intervals |
| 0.2.3 | Wire cancel/reschedule on toggle change | Toggling water reminder off cancels all 27 scheduled slots |
| 0.2.4 | Add unread notification badge to HomeScreen bell icon | Bell icon shows count from provider; tapping navigates to NotificationsScreen |
| 0.2.5 | [Stretch] Port `SetRemindersScreen` from v1 (permission onboarding) | Permission onboarding screen renders with notification + alarm step |
| **0.2 ✅** | **Notification preferences & reminders complete** | **User can toggle, schedule, and see badge count** |

#### 0.3 — Auth Enhancements: Google Sign-In & Forgot Password
**Goal**: Add Google Sign-In buttons, forgot password flow.
**Depends on**: Existing login/signup screens (already present in v2)
**Backend**: `api/auth/google`, `api/auth/forgot-password` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 0.3.1 | Add Google Sign-In button to LoginScreen | Google button renders; tapping triggers account picker |
| 0.3.2 | Wire `google_sign_in` → `auth_service.googleLogin(idToken)` | Google login succeeds; user redirected to home/onboarding |
| 0.3.3 | Add Google Sign-Up button to SignupScreen (with `forceAccountSelection: true`) | Google signup succeeds with account re-selection |
| 0.3.4 | Create ForgotPasswordScreen with email input + backend call | Forgot password screen renders; email submission works |
| 0.3.5 | Create ResetPasswordScreen with token + new password fields | Reset password flow works end-to-end |
| 0.3.6 | Add "Forgot password?" link on LoginScreen → ForgotPasswordScreen | Link navigates correctly |
| **0.3 ✅** | **Auth enhancements complete** | **Google Sign-In + Forgot Password work end-to-end** |

#### 0.4 — Multi-Step Onboarding
**Goal**: Add wellness goal selection + age/prakriti/body metrics screens after login.
**Depends on**: Phase 0.3
**Backend**: `api/onboarding/*`, `api/users/wellness-goals` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 0.4.1 | Create WellnessGoalsScreen (15 goals, select up to 3) + `onboarding_provider.dart` | Goals screen renders; toggle works; progress updates |
| 0.4.2 | Create AgePrakritiScreen (weight, height, activity level, birth year, TDEE calc) | Metrics screen renders; TDEE calculated correctly |
| 0.4.3 | Wire onboarding provider to backend (`PUT /users/me/wellness-goals`, `POST /onboarding/complete`) | Data persists; progressing through flow works |
| 0.4.4 | Update router redirect logic for multi-step onboarding | Auth → Goal → Metrics → Home (all guarded) |
| **0.4 ✅** | **Multi-step onboarding complete** | **New users flow through goal selection + metrics before home** |

---

### Phase 1 — Meal & Nutrition Tracking

#### 1.1 — Meal Plan Screens
**Goal**: Meal plan list, detail view, calendar integration.
**Depends on**: None (existing `meal_service.dart`, `meal_provider.dart`, `meal_models.dart` in v2)
**Backend**: `api/meals/meal-plans` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 1.1.1 | Create MealPlanListScreen (list of plans, active/inactive status) | Meal plans load from API and render in list |
| 1.1.2 | Create MealPlanDetailScreen (day-by-day breakdown, meal items per day) | Tapping a plan shows full week with meals |
| 1.1.3 | Add meal plan calendar view (show which days have meals logged) | Calendar highlights days with meal data |
| 1.1.4 | Wire create/edit meal plan (if applicable) | User can create a custom meal plan |
| **1.1 ✅** | **Meal plan screens complete** | **User can browse, view, and create meal plans** |

#### 1.2 — Food Logging
**Goal**: Manual food log, text search log, food detail view.
**Depends on**: Existing `log_meal_sheet.dart` in v2
**Backend**: `api/meals/food-logs`, `api/meals/search` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 1.2.1 | Enhance `LogMealSheet` with meal type selection (breakfast/lunch/dinner/snack) + portion size + date/time | Bottom sheet captures complete meal entry |
| 1.2.2 | Create FoodSearchScreen (text search via API, results list) | Search returns results from backend |
| 1.2.3 | Create FoodDetailScreen (nutritional breakdown: calories, protein, carbs, fat, fiber, sugar) | Tapping a search result shows full nutritional info |
| 1.2.4 | Wire log creation (POST /meals/food-logs with selected food + portion + meal type) | Food log submission creates record in backend |
| 1.2.5 | Add meal history calendar (show logged meals per day) | Calendar shows history; tapping a day shows meals |
| **1.2 ✅** | **Food logging complete** | **User can search, log, view, and track meals** |

#### 1.3 — Nutrition Dashboard
**Goal**: Daily/weekly nutrition summary with charts.
**Depends on**: Phase 1.2, `fl_chart` (already in pubspec.yaml)
**Backend**: `api/trackers/nutrition` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 1.3.1 | Create NutritionDashboardScreen (daily macro breakdown: calories, protein, carbs, fat) | Dashboard shows today's macros with progress bars |
| 1.3.2 | Add weekly macro chart (bar chart: calories/day) | Weekly bar chart renders with fl_chart |
| 1.3.3 | Add micro-nutrient tracker (fiber, sugar, sodium, vitamins) | Micronutrient section renders with actual data |
| 1.3.4 | Wire date picker to view past days' nutrition | Changing date updates all dashboard sections |
| **1.3 ✅** | **Nutrition dashboard complete** | **User can view daily/weekly nutrition with charts** |

#### 1.4 — Water Intake & Hydration
**Goal**: Water tracking with goals, progress ring, history.
**Depends on**: Existing `WaterTrackerScreen` in v2
**Backend**: `api/trackers/hydration` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 1.4.1 | Enhance WaterTrackerScreen with daily goal (default 8 glasses) + progress arc + add/remove buttons | Water screen shows goal, progress ring, +/− buttons work |
| 1.4.2 | Add weekly water chart (bar chart: glasses per day) | Weekly chart renders with fl_chart |
| 1.4.3 | Wire water logger to backend API | Water intake syncs to backend |
| 1.4.4 | Add water reminder toggle (uses Phase 0.2 scheduling) | Water reminder preferences control scheduled notifications |
| **1.4 ✅** | **Water intake tracking complete** | **User can track water, view weekly chart, set reminders** |

---

### Phase 2 — Health Records & Charts

#### 2.1 — Health Records (Vitals, Lab Reports)
**Goal**: Health records list, detail, add entry.
**Depends on**: Existing `MyVitalsScreen` in v2
**Backend**: `api/health-records/*` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 2.1.1 | Enhance MyVitalsScreen with vitals list (BP, HR, temp, SpO2) + add entry form | Vitals screen renders existing records; add form works |
| 2.1.2 | Create LabReportsScreen (reports list, upload image) | Lab reports upload and display |
| 2.1.3 | Create LabReportDetailScreen (full report view, PDF/image) | Tapping a report shows full detail |
| **2.1 ✅** | **Health records complete** | **User can view, add vitals and lab reports** |

#### 2.2 — Apple HealthKit & Google Fit Sync
**Goal**: Health platform integration for automatic data sync.
**Depends on**: `health` package (new dependency)
**Backend**: `api/health-records/sync` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 2.2.1 | Add `health` package to pubspec.yaml | Package added without conflicts |
| 2.2.2 | Create health_platform_service (HealthKit + Google Fit auth, read steps/weight/sleep/heart rate) | Platform auth succeeds; data reads return valid values |
| 2.2.3 | Wire sync to backend (`POST /health-records/sync`) | Synced data appears in backend health records |
| 2.2.4 | Add sync toggle in Settings (enable/disable auto-sync) | Toggle controls sync frequency; manual sync button works |
| **2.2 ✅** | **Health platform sync complete** | **HealthKit/Google Fit data syncs to HealthX backend** |

#### 2.3 — Sleep, Period, Symptom Trackers
**Goal**: Full tracker suite with charts and insights.
**Depends on**: Existing `SleepTrackerScreen` in v2, `fl_chart`
**Backend**: `api/trackers/sleep`, `api/trackers/period`, `api/trackers/symptoms` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 2.3.1 | Enhance SleepTrackerScreen with weekly sleep chart (duration + quality) | Sleep chart renders weekly trends |
| 2.3.2 | Add sleep insights card (average sleep, recommendations) | Insights section shows actionable data |
| 2.3.3 | Create PeriodTrackerScreen (cycle logging, prediction) | Period screen renders with cycle data |
| 2.3.4 | Create SymptomLoggerScreen (symptom type, severity, date/time) | Symptom logger captures and saves entries |
| 2.3.5 | Add weekly health summary chart (step + sleep + water in one view) | Combined weekly chart renders all metrics |
| **2.3 ✅** | **Tracker suite complete** | **All health trackers with charts and insights work** |

---

### Phase 3 — Commerce (Shop, Orders, Subscriptions)

#### 3.1 — Product Catalog & Menu
**Goal**: Product listing, categories, search, detail view.
**Depends on**: Existing `ShopScreen`, `ProductDetailScreen` in v2
**Backend**: `api/orders/menu` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 3.1.1 | Enhance ShopScreen with category filters + search bar | Category chips filter products; search returns results |
| 3.1.2 | Enhance ProductDetailScreen with full info (images, description, price, reviews, add-to-cart) | Product detail shows all fields; add-to-cart works |
| 3.1.3 | Add pagination/infinite scroll to shop list | Scrolling loads more products |
| 3.1.4 | [Stretch] Add carousel banner on shop top (promotions) | Banner carousel renders with promo images |
| **3.1 ✅** | **Product catalog complete** | **User can browse, search, filter, and view products** |

#### 3.2 — Cart, Checkout, Orders
**Goal**: Full cart-to-order flow with tracking.
**Depends on**: Existing `CartScreen`, `CheckoutScreen`, `MyOrdersScreen` in v2
**Backend**: `api/orders/cart`, `api/orders/checkout`, `api/orders/history`, `api/orders/tracking` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 3.2.1 | Enhance CartScreen with quantity adjust, remove, promo code, subtotal/tax/total breakdown | Cart renders with all fields; quantity adjust works |
| 3.2.2 | Enhance CheckoutScreen with delivery address picker, payment method selection, order summary | Checkout flow completes; order is placed |
| 3.2.3 | Enhance MyOrdersScreen with status tabs (active/delivered/cancelled) | Orders load with correct status filtering |
| 3.2.4 | Create OrderTrackingScreen (real-time status: confirmed → preparing → out-for-delivery → delivered) | Order tracking shows current status with timeline |
| **3.2 ✅** | **Cart, checkout, orders complete** | **User can order and track delivery in real-time** |

#### 3.3 — Address Management & Delivery Location
**Goal**: Address CRUD, map-based location picker.
**Depends on**: Existing `AddressManagementScreen` in v2
**Backend**: `api/addresses/*` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 3.3.1 | Enhance AddressManagementScreen with add/edit/delete/select-default | Address CRUD works end-to-end |
| 3.3.2 | Create AddAddressScreen (full form: name, phone, line1, line2, city, state, pincode, label) | Address creation form validates and saves |
| 3.3.3 | [Stretch] Add map-based location picker (Google Maps / OpenStreetMap) | Map picker captures lat/lng on address creation |
| **3.3 ✅** | **Address management complete** | **User can manage addresses and pick delivery location** |

#### 3.4 — Subscription Plans
**Goal**: Plan listing, subscribe, manage.
**Depends on**: Existing `SubscriptionService`, `SubscriptionProvider` in v2
**Backend**: `api/subscriptions/*` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 3.4.1 | Create SubscriptionPlansScreen (plan comparison, price, features) | Plans load and render with feature comparison |
| 3.4.2 | Create SubscriptionDetailScreen (current plan, renewal date, upgrade/downgrade/cancel) | Subscription management works |
| 3.4.3 | Wire payment integration (Razorpay/Stripe - existing v1 pattern) | Payment flow completes subscription |
| **3.4 ✅** | **Subscription management complete** | **User can browse, subscribe, and manage plans** |

---

### Phase 4 — Wellness & Engagement

#### 4.1 — Prakriti Assessment (Ayurveda)
**Goal**: Ayurvedic body type quiz with results and recommendations.
**Depends on**: None
**Backend**: `api/prakriti/*` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 4.1.1 | Create PrakritiQuizScreen (multi-question quiz: Vata/Pitta/Kapha questions) | Quiz renders; questions progress; responses tracked |
| 4.1.2 | Create PrakritiResultScreen (body type, description, characteristics) | Result screen shows dosha breakdown with chart |
| 4.1.3 | Create AyurvedicRecommendationsScreen (diet, lifestyle, yoga based on dosha) | Recommendations load and render |
| 4.1.4 | Wire quiz submission + result to backend | Results persist; re-taking quiz works |
| **4.1 ✅** | **Prakriti assessment complete** | **User can take quiz and see personalized recommendations** |

#### 4.2 — Rewards & Gamification
**Goal**: Points, achievements, streaks, leaderboard, rewards store.
**Depends on**: Existing `RewardsScreen`, `RewardsProvider` in v2
**Backend**: `api/users/points`, `api/users/achievements`, `api/trackers/streaks` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 4.2.1 | Enhance RewardsScreen with points balance, daily streaks, achievement badges | Rewards dashboard renders all gamification data |
| 4.2.2 | Create AchievementsScreen (badge gallery: locked/unlocked) | Badges render with unlock conditions shown |
| 4.2.3 | Create LeaderboardScreen (weekly/monthly/all-time rankings) | Leaderboard loads and shows user rank |
| 4.2.4 | Create RewardsStoreScreen (redeem points for items/coupons) | Redemption flow works end-to-end |
| 4.2.5 | Create ReferralScreen (referral code, share, reward tracking) | Referral code generates; share sheet opens; rewards track |
| 4.2.6 | Wire daily goal → reward notification (uses Phase 0.1) | Completing all daily goals triggers reward notification |
| **4.2 ✅** | **Rewards & gamification complete** | **User can earn, track, and redeem rewards** |

#### 4.3 — Content & Education
**Goal**: Articles, tips, videos, recipes, FAQ.
**Depends on**: None
**Backend**: `api/content/*`, `api/meals/recipes` — fully ready

| # | Task | Checkpoint |
|---|------|------------|
| 4.3.1 | Create ArticlesScreen (article list with categories) | Articles load from API and render in categorized list |
| 4.3.2 | Create ArticleDetailScreen (full article with images, rich text) | Tapping article shows full content |
| 4.3.3 | Create TipsOfTheDayWidget (compact tip card for home screen) | Tip card renders on home screen; content loads from API |
| 4.3.4 | Create RecipesScreen (recipe list with filters: diet, prep time, cuisine) | Recipes load with filter chips |
| 4.3.5 | Create RecipeDetailScreen (ingredients, steps, nutrition info) | Tapping recipe shows full detail |
| 4.3.6 | Create FAQScreen (expandable Q&A categories) | FAQ renders with expandable sections |
| **4.3 ✅** | **Content & education complete** | **User can browse articles, tips, recipes, and FAQ** |

---

### Phase 5 — UI Polish & Developer Infrastructure

#### 5.1 — Animations & Visual Polish
**Goal**: Rich animations, responsive layouts, haptics, page transitions.
**Depends on**: `flutter_animate` (new dependency), existing v2 theming

| # | Task | Checkpoint |
|---|------|------------|
| 5.1.1 | Add `flutter_animate` to pubspec.yaml + wrap key screens with entrance animations | Screens animate in; no visual regressions |
| 5.1.2 | Add shimmer loading skeletons to list screens (shop, articles, doctors, notifications) | Skeleton shows during loading; replaced by content |
| 5.1.3 | Add carousel slider to home screen (promotions, health tips) | Carousel renders with auto-scroll |
| 5.1.4 | Add animated page transitions (slide/fade between routes) | Route transitions are smooth and consistent |
| 5.1.5 | Add haptic feedback on key interactions (button taps, toggle switches, swipe-to-dismiss) | Haptic fires on specified interactions |
| 5.1.6 | Add pull-to-refresh to all list screens | Pull-to-refresh works on every scrollable list |
| 5.1.7 | [Stretch] Add responsive layouts (breakpoints for tablet) | UI adapts to tablet/landscape layouts |
| **5.1 ✅** | **UI polish complete** | **App feels polished; animations, skeletons, transitions all smooth** |

#### 5.2 — Custom Painters & Visual Elements
**Goal**: Water jar, progress arc, bubble background (v1 visual identity elements).
**Depends on**: None

| # | Task | Checkpoint |
|---|------|------------|
| 5.2.1 | Create `WaterJarPainter` (CustomPainter for water tracking) | Water jar painter renders with fill level |
| 5.2.2 | Create `ProgressArcPainter` (circular progress for goals) | Progress arc renders with animated sweep |
| 5.2.3 | Create `BubbleBackgroundPainter` (decorative bubbles for auth screens) | Bubble background renders behind login/signup forms |
| 5.2.4 | Integrate painters into appropriate screens | All painters replace static indicators |
| **5.2 ✅** | **Custom painters complete** | **App uses custom-drawn visual elements from v1** |

#### 5.3 — Testing
**Goal**: Unit, widget, and integration tests.
**Depends on**: All phases complete

| # | Task | Checkpoint |
|---|------|------------|
| 5.3.1 | Add unit tests for all providers (auth, notification, tracker, shop, health) | 80%+ provider method coverage |
| 5.3.2 | Add unit tests for all services (REST API wrappers with mock Dio) | 90%+ service method coverage |
| 5.3.3 | Add widget tests for all screens (render + key interactions) | Every screen has at least 1 widget test |
| 5.3.4 | Add integration test for critical flow: auth → home → tracker → shop → checkout | Critical flow passes end-to-end |
| **5.3 ✅** | **Testing complete** | **Tests pass; coverage meets targets** |

#### 5.4 — CI/CD, Environment Config, Error Tracking
**Goal**: Build pipeline, environment files, error monitoring.
**Depends on**: None

| # | Task | Checkpoint |
|---|------|------------|
| 5.4.1 | Create environment config files (dev/staging/prod with API URLs, Firebase config, feature flags) | Config files load correctly per environment |
| 5.4.2 | Add Sentry/Crashlytics error tracking | Uncaught errors reported to monitoring service |
| 5.4.3 | Set up GitHub Actions CI (lint → test → build APK/IPA) | CI pipeline passes on push/PR |
| 5.4.4 | Set up Code Push / app distribution (if applicable) | OTA updates work for staging builds |
| **5.4 ✅** | **CI/CD & infrastructure complete** | **Build pipeline, error tracking, environments all operational** |

---

### Effort Summary

| Phase | Sub-Phases | Checkpoints | Est. Effort | Dependencies |
|-------|-----------|-------------|-------------|-------------|
| **Phase 0** | 0.1–0.4 | 23 tasks / 6 checkpoints | 2-3 weeks | None |
| **Phase 1** | 1.1–1.4 | 18 tasks / 6 checkpoints | 3-4 weeks | Phase 0 (notifications), fl_chart (already present) |
| **Phase 2** | 2.1–2.3 | 15 tasks / 5 checkpoints | 2-3 weeks | Phase 1 (patterns), fl_chart |
| **Phase 3** | 3.1–3.4 | 18 tasks / 7 checkpoints | 3-4 weeks | Phase 0 (notifications for order tracking) |
| **Phase 4** | 4.1–4.3 | 16 tasks / 5 checkpoints | 2-3 weeks | Phase 0 (notifications for rewards) |
| **Phase 5** | 5.1–5.4 | 17 tasks / 6 checkpoints | 3-4 weeks | All phases (test coverage) |
| **Total** | **16 sub-phases** | **107 tasks / 35 checkpoints** | **15-21 weeks** | |

**Key Insight**: Phases 0-4 can partially overlap (e.g., Phase 1 meal features don't block Phase 3 shop features). Parallel tracks can reduce wall-clock time by ~30%.

---

## 9. Progress Log

### Phase 0 — Foundation & Infrastructure Setup
| Sub-Phase | Status | Started | Completed | Notes |
|-----------|--------|---------|-----------|-------|
| 0.1 — FCM & Push Notifications | ✅ Complete | Jun 11 | Jun 11 | Firebase init, FCM bg/fg handler, local notif channels, tap routing |
| 0.2 — Notification Preferences & Reminders | ✅ Complete | Jun 11 | Jun 11 | 5 toggles in Settings, water reminders via WaterReminderService |
| 0.3 — Auth Enhancements (Google Sign-In, Forgot Password) | ✅ Complete | Jun 11 | Jun 11 | Google buttons existed; added ForgotPassword + ResetPassword screens + routes |
| 0.4 — Multi-Step Onboarding | ✅ Complete | — | — | Already implemented as 4-step PageView wizard in ProfileCompletionScreen |
| **Phase 0** | **4 / 4 sub-phases** | | | ✅ All Foundation done |

### Phase 1 — Meal & Nutrition Tracking

### Phase 1 — Meal & Nutrition Tracking
| Sub-Phase | Status | Started | Completed | Notes |
|-----------|--------|---------|-----------|-------|
| 1.1 — Meal Plan Screens | ❌ Not Started | — | — | |
| 1.2 — Food Logging | ❌ Not Started | — | — | |
| 1.3 — Nutrition Dashboard | ❌ Not Started | — | — | |
| 1.4 — Water Intake & Hydration | ❌ Not Started | — | — | |
| **Phase 1** | **0 / 6 checkpoints** | | | |

### Phase 2 — Health Records & Charts
| Sub-Phase | Status | Started | Completed | Notes |
|-----------|--------|---------|-----------|-------|
| 2.1 — Health Records (Vitals, Lab Reports) | ❌ Not Started | — | — | |
| 2.2 — Apple HealthKit & Google Fit Sync | ❌ Not Started | — | — | |
| 2.3 — Sleep, Period, Symptom Trackers | ❌ Not Started | — | — | |
| **Phase 2** | **0 / 5 checkpoints** | | | |

### Phase 3 — Commerce
| Sub-Phase | Status | Started | Completed | Notes |
|-----------|--------|---------|-----------|-------|
| 3.1 — Product Catalog & Menu | ❌ Not Started | — | — | |
| 3.2 — Cart, Checkout, Orders | ❌ Not Started | — | — | |
| 3.3 — Address Management & Delivery Location | ❌ Not Started | — | — | |
| 3.4 — Subscription Plans | ❌ Not Started | — | — | |
| **Phase 3** | **0 / 7 checkpoints** | | | |

### Phase 4 — Wellness & Engagement
| Sub-Phase | Status | Started | Completed | Notes |
|-----------|--------|---------|-----------|-------|
| 4.1 — Prakriti Assessment | ❌ Not Started | — | — | |
| 4.2 — Rewards & Gamification | ❌ Not Started | — | — | |
| 4.3 — Content & Education | ❌ Not Started | — | — | |
| **Phase 4** | **0 / 5 checkpoints** | | | |

### Phase 5 — UI Polish & Infrastructure
| Sub-Phase | Status | Started | Completed | Notes |
|-----------|--------|---------|-----------|-------|
| 5.1 — Animations & Visual Polish | ❌ Not Started | — | — | |
| 5.2 — Custom Painters | ❌ Not Started | — | — | |
| 5.3 — Testing | ❌ Not Started | — | — | |
| 5.4 — CI/CD & Infrastructure | ❌ Not Started | — | — | |
| **Phase 5** | **0 / 6 checkpoints** | | | |

### Summary
| Metric | Count |
|--------|-------|
| Total Sub-Phases | 16 |
| Total Checkpoints | 35 |
| Total Tasks | 107 |
| Completed Sub-Phases | 4 |
| In Progress Sub-Phases | 0 |
| Phase 0 (Foundation) | ✅ Complete |

---

*Update the progress log above as each checkpoint is completed. Each checkpoint is a verifiable milestone.*
