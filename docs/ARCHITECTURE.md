# HealthX Backend Architecture - Comprehensive Design Document

**Version**: 1.0  
**Status**: Ready for Implementation  
**Target Scale**: 100,000+ concurrent users

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [System Design Layers](#system-design-layers)
4. [API Architecture](#api-architecture)
5. [Service Layer Design](#service-layer-design)
6. [Data Architecture](#data-architecture)
7. [Integration Layer](#integration-layer)
8. [Deployment Architecture](#deployment-architecture)
9. [Key Workflows](#key-workflows)
10. [Technology Stack](#technology-stack)
11. [Implementation Phases](#implementation-phases)
12. [Performance & Scalability](#performance--scalability)
13. [Security & Compliance](#security--compliance)
14. [Monitoring & Observability](#monitoring--observability)

---

## Executive Summary

**HealthX** is a comprehensive health & wellness platform backend designed to support a feature-rich mobile application. The architecture is built on modern, scalable principles with:

- **11 Core Service Domains** organized by business logic
- **18 MongoDB Collections** with optimized relationships
- **65+ REST API Endpoints** following RESTful standards
- **Real-time Capabilities** via WebSockets for telemedicine
- **Asynchronous Processing** via Bull message queues
- **Multi-provider Integration** (Wearables, Payments, Notifications)
- **HIPAA-Compliant** security with encryption & audit logging
- **Horizontal Scalability** with stateless design

**Key Metrics Target**:
| Metric | Target |
|--------|--------|
| API Response Time (p95) | <100ms |
| Concurrent Users | 10,000+ |
| Uptime | 99.9% |
| Telemedicine Latency | <500ms |
| Data Sync Latency (Wearables) | <1 hour |

---

## Architecture Overview

### High-Level System Architecture

The HealthX backend follows a **layered, domain-driven architecture** with clear separation of concerns:

```
┌─────────────────────────────────────┐
│      Client Layer (Mobile App)      │
│         (Flutter - iOS/Android)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Load Balancer & API Gateway        │
│  (Nginx/AWS ALB, Rate Limiting)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  API Layer (Express.js)             │
│  (Middleware Pipeline, Routes)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Service Layer (11 Domains)         │
│  (Business Logic Encapsulation)     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Repository/Data Layer (Optional)   │
│  (Data Access Abstraction)          │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  Data & Persistence Layer           │
│  (MongoDB, Redis, Message Queues)   │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│  External Integration Layer         │
│  (Wearables, Razorpay, FCM, S3)     │
└─────────────────────────────────────┘
```

---

## System Design Layers

### 1. Client Layer (Flutter Frontend)

The frontend application is built using Flutter (iOS/Android/Web) following a clean, decoupled architectural design pattern:

```
┌──────────────────────────────────┐
│     Flutter UI Layer             │
│   (Screens, Widgets, Painters)   │
└────────────────┬─────────────────┘
                 │
┌────────────────▼─────────────────┐
│   State Management Layer          │
│   (Provider, local controllers)  │
└────────────────┬─────────────────┘
                 │
┌────────────────▼─────────────────┐
│   Service Layer                  │
│   (API Client, Local Services)   │
└────────────────┬─────────────────┘
                 │
┌────────────────▼─────────────────┐
│   Local Storage & Cache          │
│   (SharedPreferences, Hive)      │
└────────────────┬─────────────────┘
                 │
┌────────────────▼─────────────────┐
│   Platform-Specific Services     │
│   (Health Kit, Health Connect)   │
└──────────────────────────────────┘
```

- **Flutter UI Layer**: Declarative layout using screens and reusable UI widgets. Features a responsive framework with cross-device and tablet compatibility.
- **State Management**:
  - `Provider` package to broadcast app-wide state (authentication, shopping cart, user preferences, loyalty rewards).
  - Dependency Injection managed via `GetIt` for service and client locators.
- **Service Layer**:
  - `Dio` HTTP client configured with request/response logging, automatic auth token header injection, and retry/refresh interceptors.
  - `WebSocket` client for real-time peer-to-peer telemedicine messaging/consultations.
  - Background synchronization manager to regularly ingest health data.
- **Local Storage & Caching**:
  - `Hive` NoSQL database for caching static search content and meal plan information offline.
  - `SharedPreferences` for user session settings and UI state flags.
  - `flutter_secure_storage` for storing JWT access and refresh tokens.
- **Platform Specific**:
  - Android: `Health Connect` API for background step counting, activity recognition, and workout logging.
  - iOS: `HealthKit` API mapping step count and vital metrics directly from Apple Health.

### 2. API Gateway & Load Balancing

- **Load Balancer**: AWS ALB (Application Load Balancer)
- **Functions**:
  - HTTPS/TLS termination
  - Health check monitoring
  - Request routing to API servers
  - Rate limiting (per IP/user)
  - CORS handling
- **Scaling**: Auto-scaling group (3-10 instances)

### 3. API Layer (Request/Response Pipeline)

```
HTTP Request
    ↓
CORS Handler (Validate origin)
    ↓
Auth Middleware (Verify JWT)
    ↓
Request Validator (Zod schemas)
    ↓
Audit Logger (Log all access)
    ↓
RBAC Check (Permission verification)
    ↓
Route Handler (Dispatch to controller)
    ↓
Controller (Call service layer)
    ↓
Service (Business logic)
    ↓
Response Handler (JSON format)
    ↓
Error Handler (Centralized)
    ↓
HTTP Response
```

**Key Middleware Components**:

- `corsMiddleware` - Cross-origin validation
- `authMiddleware` - JWT verification
- `requestValidator` - Input validation with Zod
- `auditLogger` - Request/response logging
- `rbacMiddleware` - Role-based access control
- `errorMiddleware` - Global error handling
- `rateLimiter` - Prevent abuse

### 4. Service Layer (Domain-Driven)

**11 Domain Services**:

1. **Authentication Domain**
   - OAuth handler, JWT creation, token refresh
   - Role-based access control

2. **Health Tracking Domain**
   - Wearable data ingestion & aggregation
   - Health goal management & progress tracking

3. **Healthcare Domain**
   - Doctor/provider search & management
   - Appointment booking & slot management
   - Telemedicine session handling

4. **Meal & Diet Domain**
   - Meal plan browsing & customization
   - Diet order processing & subscription management

5. **Payments Domain**
   - Razorpay checkout & invoice generation
   - Payment webhook handling & refunds
   - Indian rupee (INR) support

6. **Loyalty Domain**
   - Referral code generation & tracking
   - Reward calculations & redemption

7. **Notifications Domain**
   - Push notifications via Firebase FCM
   - Email/SMS via SendGrid/Twilio
   - In-app messaging

8. **Reminder Domain**
   - Appointment reminders (scheduled)
   - Medication/delivery alerts
   - Async job processing

9. **Integration Domain**
   - Wearable device adapters (Apple, Google, Fitbit)
   - Third-party API interactions

10. **Caching Domain**
    - Redis-based caching strategy
    - Cache invalidation logic

11. **Utilities Domain**
    - Field-level encryption
    - Input validation (Zod schemas)
    - Logging & error handling

### 5. Repository/Data Access Layer (Optional)

- **When to use**: For complex queries or when scaling to microservices
- **Pattern**: Repository pattern for data abstraction
- **Benefit**: Easy to switch databases or add query optimization

### 6. Data Persistence Layer

- **Primary Database**: MongoDB (NoSQL)
- **Cache Layer**: Redis (in-memory)
- **Message Queue**: Bull (Redis-backed)
- **Blob Storage**: AWS S3

### 7. Integration Layer

External services connected via adapters:

- **Wearables**: Apple Health, Google Fit, Fitbit (Adapter pattern)
- **Payments**: Razorpay API (Indian payment gateway)
- **Notifications**: Firebase FCM, SendGrid, Twilio
- **Storage**: AWS S3

---

## API Architecture

### Request/Response Pipeline

**Request Flow**:

1. **Client** sends HTTP request (HTTPS)
2. **ALB** routes to API instance
3. **Express middleware chain** processes request:
   - CORS validation
   - JWT authentication
   - Input validation (Zod)
   - Request audit logging
   - RBAC permission check
4. **Route handler** dispatches to controller
5. **Controller** calls service layer
6. **Service** performs business logic:
   - Database queries
   - Cache lookups/updates
   - External API calls
7. **Response** constructed in standard format
8. **Error middleware** catches any errors
9. **Client** receives JSON response

**Response Format** (Standardized):

```typescript
{
  statusCode: 200,
  message: "Success",
  data: { /* payload */ }
}
```

**Error Format**:

```typescript
{
  statusCode: 400,
  message: "User not found",
  error: "NOT_FOUND",
  timestamp: "2026-05-08T12:30:00Z"
}
```

### API Endpoint Organization

**65+ Endpoints** organized by domain:

| Domain          | Endpoints | Examples                                                       |
| --------------- | --------- | -------------------------------------------------------------- |
| Auth            | 5         | POST /auth/google, POST /auth/refresh                          |
| Health Tracking | 8         | GET /health-metrics, POST /health-metrics/sync                 |
| Health Goals    | 10        | GET /health-goals, POST /health-goals/:id/progress             |
| Providers       | 7         | GET /providers, GET /providers/:id/slots                       |
| Appointments    | 8         | POST /appointments, PUT /appointments/:id                      |
| Meal Plans      | 12        | GET /diet/plans, POST /diet/orders                             |
| Subscriptions   | 8         | POST /subscriptions, PUT /subscriptions/:id                    |
| Payments        | 5         | POST /payments/checkout, POST /payments/webhook                |
| Consultations   | 6         | POST /consultations/:id/start, GET /consultations/:id/messages |
| Referrals       | 5         | POST /referrals/invite, GET /referrals/rewards                 |
| Notifications   | 4         | GET /notifications, PUT /notifications/:id/read                |
| Corporate       | 5         | GET /corporate/plans, POST /corporate/teams                    |
| Admin           | 10+       | GET /admin/users, POST /admin/banners                          |

---

## Service Layer Design

### Domain-Driven Architecture

Each domain is self-contained with:

- **Service**: Business logic implementation
- **Repository**: Data access abstraction (optional)
- **Controllers**: Request handling
- **Routes**: Endpoint definitions
- **Validators**: Zod schemas

### Service Responsibilities

#### Authentication Service

```
Responsibilities:
- Google OAuth token validation
- JWT token creation/refresh
- Token blacklisting on logout
- OAuth "Identify & Link" user resolution
```

#### Health Metrics Service

```
Responsibilities:
- Accept wearable data ingestion
- Aggregate metrics by time period
- Calculate statistics (avg, max, min)
- Cache frequently accessed data
- Sync with wearable providers (polling)
```

#### Health Goal Service

```
Responsibilities:
- Manage 15 health goal types
- Track user's selected goals
- Log progress entries
- Recommend meals based on goals
- Calculate achievement metrics
```

#### Appointment Service

```
Responsibilities:
- Validate slot availability
- Create appointment bookings
- Send reminder notifications
- Handle rescheduling/cancellation
- Manage slot conflict resolution
```

#### Diet Order Service

```
Responsibilities:
- Validate meal plan selections
- Process orders through Razorpay
- Create subscription records
- Track delivery status
- Handle refunds/cancellations
```

#### Payment Service

```
Responsibilities:
- Create Razorpay orders
- Validate webhook signatures
- Update order status on payment
- Generate invoices
- Handle refunds & disputes
- Support multiple payment methods (UPI, Cards, Wallets)
```

#### Notification Service

```
Responsibilities:
- Send push notifications (FCM)
- Send emails (SendGrid)
- Send SMS (Twilio)
- Store notification history
- Track read/delivered status
```

### Shared Utilities

All services use:

1. **Encryption Utility**
   - Encrypt sensitive fields (SSN, card info)
   - Decrypt on retrieval
   - Uses node's `crypto` module

2. **Caching Utility**
   - Redis wrapper with TTL management
   - Cache key generation
   - Invalidation logic

3. **Validation Utility**
   - Zod schema definitions
   - Request/response validation
   - Error message generation

4. **Logging Utility**
   - Winston logger integration
   - Structured JSON logging
   - Audit trail tracking

5. **Error Handling**
   - Custom AppError class
   - Async error wrapper (catchAsync)
   - Centralized error middleware

---

## Data Architecture

### Database Design

**MongoDB Collections** (18 total):

#### User & Authentication Domain

- **User**: Base user entity (name, email, googleId, role)
- **Patient**: Patient profile extension (medical history, preferences)

#### Health Tracking Domain

- **HealthMetrics**: Time-series wearable data
  - Index: `{ userId: 1, timestamp: -1 }`
  - TTL: 30 days (optional)
- **HealthGoal**: 15 pre-defined health goals
  - Index: `{ _id: 1 }`
  - Pre-seeded on DB init
- **HealthGoalProgress**: User's progress for each goal
  - Index: `{ userId: 1, goalId: 1 }`

#### Healthcare Domain

- **HealthcareProvider**: Doctor/specialist profiles
  - Index: `{ specialty: 1, rating: -1 }`
- **AppointmentSlot**: Available time slots
  - Index: `{ providerId: 1, dateTime: 1 }`
- **Appointment**: Booked appointments
  - Index: `{ userId: 1, dateTime: -1 }`
- **ConsultationSession**: Telemedicine sessions
  - Index: `{ appointmentId: 1 }`

#### Meal & Diet Domain

- **MealPlan**: Meal plan types (Healthy Bowl, Zym Bowl, etc.)
  - Pre-seeded on DB init
- **MealPlanOption**: Plan variants (Weekly, Monthly, Custom)
- **Meal**: Individual meals with nutrition
  - Index: `{ goalMappings: 1 }`
- **DietOrder**: Meal delivery orders
  - Index: `{ userId: 1, createdAt: -1 }`
- **Subscription**: Recurring subscriptions
  - Index: `{ userId: 1, status: 1, nextBillingDate: 1 }`

#### Business Domain

- **Payment**: Transaction records
  - Index: `{ userId: 1, createdAt: -1 }`
- **Referral**: Referral program tracking
  - Index: `{ userId: 1, code: 1 }`

#### Communication Domain

- **Notification**: Push/email/SMS notifications
  - Index: `{ userId: 1, createdAt: -1 }`

### Data Relationships

**Key Relationships**:

```
User (1) ──┬─→ (M) HealthMetrics
           ├─→ (M) HealthGoalProgress
           ├─→ (M) Appointment
           ├─→ (M) ConsultationSession
           ├─→ (M) DietOrder
           ├─→ (M) Subscription
           ├─→ (M) Payment
           ├─→ (M) Referral
           └─→ (M) Notification

HealthGoal (1) ──→ (M) HealthGoalProgress
             └──→ (M) Meal

HealthcareProvider (1) ──→ (M) AppointmentSlot
                    └──→ (M) Appointment

AppointmentSlot (1) ──→ (M) Appointment
Appointment (1) ──────→ (1) ConsultationSession
            └──────────→ (M) Payment

MealPlan (1) ──→ (M) MealPlanOption
        ├──→ (M) Meal
        └──→ (M) DietOrder

MealPlanOption (1) ──→ (M) DietOrder
               └──→ (M) Subscription

DietOrder (1) ──→ (1) Payment
Subscription (1) ──→ (M) Payment
```

### Caching Strategy

**Redis Cache Layers**:

| Data Type                 | TTL              | Use Case                            |
| ------------------------- | ---------------- | ----------------------------------- |
| Health Goals (all 15)     | 24 hours         | Frequently accessed, rarely changes |
| User Profile              | Session duration | Avoid DB hits on each request       |
| Meal Plans                | 24 hours         | Browse operations                   |
| Appointment Slots         | 6 hours          | High frequency lookups              |
| Health Metrics Aggregates | 1 hour           | Dashboard summary                   |
| Doctor Search Results     | 12 hours         | Provider directory                  |
| Referral Codes            | 7 days           | Validation & tracking               |
| FCM Tokens                | 30 days          | Push notification routing           |

**Cache Invalidation Strategy**:

- **Write-Through**: Always update DB first, then cache
- **TTL-based**: Automatic expiration
- **Event-based**: Manual invalidation on data changes
  - When slot booked → invalidate slot cache
  - When order paid → invalidate subscription cache
  - When profile updated → invalidate user cache

---

## Integration Layer

### Wearable Device Integration (Adapter Pattern)

```
Request → Wearable Adapter
            ├─→ Apple Health Adapter
            ├─→ Google Fit Adapter
            └─→ Fitbit Adapter
```

**Apple Health**:

- OAuth 2.0 authentication
- HealthKit API calls
- Metrics: Steps, heart rate, sleep, workout
- Sync frequency: Every 6 hours (polling)

**Google Fit**:

- OAuth 2.0 (Google ecosystem)
- Fit REST API endpoints
- Metrics: Steps, calories, heart rate
- Batch import capability

**Fitbit**:

- API key authentication
- REST API endpoints
- Webhook support for real-time updates
- Metrics: Steps, heart rate, sleep, nutrition

### Payment Processing (Razorpay)

**Checkout Flow**:

```
User selects meal plan → Create Razorpay Order
→ Show Razorpay Checkout (UPI/Cards/Wallets)
→ User completes payment → Webhook callback
→ Payment verified → Update order status
→ Queue delivery task
```

**Webhook Handler**:

- Validates Razorpay signature (security)
- Is idempotent (can retry safely)
- Handles events: `payment.captured`, `payment.failed`, `refund.created`

### Razorpay Integration (Indian Payment Gateway)

**Why Razorpay for India?**:

- **Market Leading**: 50%+ market share in Indian fintech
- **Local Support**: 24/7 support in IST timezone
- **Payment Methods**: UPI, Cards (Visa/Mastercard), Wallets (PayTM, Amazon Pay)
- **Settlements**: Fast settlement (T+2 banking days)
- **Compliance**: PCI-DSS, RBI regulated
- **Fees**: Competitive pricing (2-3% for most methods)

**Razorpay Payment Methods**:

```
1. UPI (Unified Payments Interface)
   - Recommended for India (60%+ users)
   - Instant settlement

2. Debit/Credit Cards
   - Visa, Mastercard, Amex
   - 3D Secure (OTP authentication)

3. Net Banking
   - All major Indian banks
   - Direct transfer

4. Mobile Wallets
   - PayTM, Amazon Pay, Google Pay
   - Pre-filled wallets for quick payment

5. EMI (Equated Monthly Installments)
   - HDFC, ICICI, Axis, Kotak
   - Subscription-friendly for meal plans
```

**Integration Flow**:

```
Create Order (API) → Razorpay API Key
    ↓
{
  "amount": 50000,        // In paise (₹500)
  "currency": "INR",
  "receipt": "receipt#1",
  "description": "Healthy Bowl Weekly Plan"
}
    ↓
Razorpay generates order_id → Return to client
    ↓
Client initializes Razorpay Checkout
    ↓
User selects payment method → Pay
    ↓
Razorpay processes payment
    ↓
Webhook: payment.captured (signed callback)
    ↓
Verify signature using API Secret
    ↓
Update database & deliver service
```

**Razorpay NPM Package**:

```typescript
const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// Create order
const order = await razorpay.orders.create({
  amount: 50000,
  currency: 'INR',
  receipt: `receipt_${Date.now()}`,
  description: 'Healthy Bowl Meal Plan',
});

// Validate webhook
const body = `${order_id}|${payment_id}`;
const expectedSignature = hmac_sha256(body, key_secret);
// Compare with provided signature
```

**Webhook Events**:
| Event | When | Action |
|-------|------|--------|
| `payment.captured` | User pays successfully | Update order → Enqueue delivery |
| `payment.failed` | Payment declined | Notify user → Retry option |
| `payment.authorized` | Card pre-auth (not settled) | Hold order temporarily |
| `refund.created` | Refund initiated | Update order status → Notify user |
| `payment.disputed` | Chargeback filed | Investigate & resolve |

**Settlement in India**:

- **T+2 Settlement**: Payment received in 2 business days
- **Live Balance**: Check balance via Razorpay dashboard
- **Reconciliation**: Automated via APIs
- **Tax Compliance**: GST handling per Indian regulations

### Notification Services

**Firebase Cloud Messaging (FCM)**:

- Store FCM tokens in user session cache
- Send push notifications to mobile app
- Track delivery status

**SendGrid (Email)**:

- Email templates for notifications
- Transactional emails (order confirmations, reminders)
- Delivery tracking

**Twilio (SMS)**:

- SMS sending for critical alerts
- OTP verification (if email auth added later)
- Delivery confirmation

### Document Storage (AWS S3)

- Store encrypted medical documents
- Pre-signed URLs for secure downloads
- Lifecycle policies (auto-delete after 30 days)
- Encryption at rest + in transit

---

## Deployment Architecture

### Production Environment

**Infrastructure**:

- **Compute**: AWS EC2 (Auto Scaling Group)
- **Load Balancing**: AWS Application Load Balancer (ALB)
- **Database**: MongoDB Atlas (managed service)
- **Cache**: AWS ElastiCache (Redis)
- **Storage**: AWS S3
- **Monitoring**: CloudWatch + DataDog
- **CDN**: CloudFront
- **Container Registry**: ECR (Elastic Container Registry)

### Scaling Strategy

**Horizontal Scaling**:

```
Auto-Scaling Group Configuration:
- Minimum instances: 3
- Maximum instances: 10
- Scale-up trigger: CPU > 70%
- Scale-down trigger: CPU < 30%
- Cooldown period: 300 seconds
```

**Database Scaling**:

- MongoDB Replica Set (3+ nodes)
- Read replicas for read-heavy operations
- Sharding ready for massive scale

**Cache Scaling**:

- Redis Primary + Replica
- Redis Sentinel for automatic failover
- Connection pooling

### CI/CD Pipeline

```
Code Push → GitHub → CI Build (GitHub Actions)
│
├─→ Lint check (ESLint)
├─→ Type check (TypeScript)
├─→ Unit tests (Jest)
├─→ Integration tests (Supertest)
│
→ Build Docker image → ECR Push
│
→ CD Deploy (ECS/EKS)
│
├─→ Blue/Green deployment
├─→ Health checks
├─→ Rollback if failed
│
→ Production (ALB → EC2 instances)
```

### Backup & Disaster Recovery

**Backup Strategy**:

- Daily automated MongoDB snapshots
- 30-day retention policy
- Cross-region replication
- Point-in-time recovery capability

**RTO/RPO**:

- **RTO** (Recovery Time Objective): 15 minutes
- **RPO** (Recovery Point Objective): 1 hour
- Disaster recovery site in different AWS region

---

## Key Workflows

### Workflow 1: Meal Ordering

```
1. User browses meal plans (GET /diet/plans)
   → Served from Redis cache

2. User selects plan & customization (POST /diet/orders)
   → Validate selection
   → Create DietOrder in MongoDB
   → Create Razorpay order

3. User completes payment on Razorpay (UPI/Card/Wallet)

4. Razorpay sends webhook: payment.captured
   → Verify signature
   → Update order status = 'paid'
   → Enqueue delivery task in Bull queue

5. Background worker (Worker process)
   → Get user FCM token from cache
   → Compose delivery notification
   → Send via Firebase FCM
   → Log notification event

6. User queries order status (GET /diet/orders/:orderId)
   → Check cache (miss)
   → Query MongoDB
   → Cache result (6h TTL)
   → Return order details
```

### Workflow 2: Doctor Appointment Booking

```
1. User searches doctors (GET /providers?specialty=cardiology)
   → Check cache (miss)
   → Query MongoDB with specialty filter
   → Cache results (12h TTL)
   → Return provider list

2. User views available slots (GET /providers/:id/slots?date=2026-05-20)
   → Check cache (hit)
   → Return slots from cache

3. User books appointment (POST /appointments)
   → Verify JWT token
   → Check RBAC permissions
   → Verify slot availability
   → Create Appointment in MongoDB
   → Invalidate slot cache
   → Enqueue reminder in Bull queue (24h before appointment)

4. Reminder queue triggers 24h before appointment
   → Get user FCM token + doctor info from cache
   → Compose reminder message
   → Send push notification via FCM

5. User reschedules (PUT /appointments/:id/reschedule)
   → Verify new slot availability
   → Update Appointment in MongoDB
   → Invalidate caches
   → Re-enqueue reminder task
```

### Workflow 3: Health Goal Tracking

```
1. User views all health goals (GET /health-goals)
   → Check cache (hit)
   → Return 15 goals from cache

2. User selects goal (POST /patients/me/health-goals/build_muscle)
   → Verify user owns selection
   → Create HealthGoalProgress in MongoDB
   → Invalidate user preference cache

3. User logs progress (POST /health-goals/:id/progress)
   → Validate progress entry (Zod schema)
   → Create progress entry in MongoDB
   → Recalculate goal statistics
   → Invalidate user cache

4. User views progress (GET /health-goals/:id/progress)
   → Query MongoDB
   → Calculate statistics
   → Get recommendations from cache
   → Return progress dashboard
```

---

## Technology Stack

### Core Technologies

| Layer               | Technology              | Version    | Purpose                |
| ------------------- | ----------------------- | ---------- | ---------------------- |
| **Runtime**         | Node.js                 | Latest LTS | Server environment     |
| **Language**        | TypeScript              | 6.0+       | Type safety            |
| **Framework**       | Express.js              | 5.2.1      | HTTP server            |
| **Database**        | MongoDB                 | 9.4.1      | Primary store          |
| **Database Client** | Mongoose                | 9.4.1      | ODM                    |
| **Cache**           | Redis                   | 7.x        | In-memory cache        |
| **Queue**           | Bull                    | 5.0.0      | Job processing         |
| **Auth**            | Passport.js             | 0.7.0      | Authentication         |
| **OAuth**           | passport-google-oauth20 | 2.0.0      | Google OAuth           |
| **JWT**             | jsonwebtoken            | 9.0.3      | Token management       |
| **Validation**      | Zod                     | 4.3.6      | Schema validation      |
| **Security**        | Helmet                  | 8.1.0      | HTTP headers           |
| **CORS**            | cors                    | 2.8.6      | Cross-origin           |
| **Logging**         | Winston                 | 3.11.0     | Structured logs        |
| **Payments**        | Razorpay                | 2.x        | Indian payment gateway |
| **Push Notify**     | firebase-admin          | 12.0.0     | FCM                    |
| **Email**           | SendGrid                | 7.7.0      | Email service          |
| **SMS**             | Twilio                  | 4.x.x      | SMS service            |
| **Cloud Storage**   | aws-sdk                 | 2.x        | AWS S3                 |
| **Error Tracking**  | Sentry                  | 7.x        | Exception tracking     |
| **Testing**         | Jest                    | 29.x       | Unit tests             |
| **HTTP Testing**    | Supertest               | 6.x        | Integration tests      |

### Development Tools

| Tool           | Purpose              |
| -------------- | -------------------- |
| ts-node        | TypeScript execution |
| nodemon        | Hot reload           |
| ESLint         | Code linting         |
| Prettier       | Code formatting      |
| Docker         | Containerization     |
| GitHub Actions | CI/CD                |

## Performance & Scalability

### Performance Targets

| Metric                  | Target  | Strategy                               |
| ----------------------- | ------- | -------------------------------------- |
| API Response Time (p95) | <100ms  | Database indexing, caching             |
| API Response Time (p99) | <500ms  | Load balancing, auto-scaling           |
| Concurrent Users        | 10,000+ | Horizontal scaling, connection pooling |
| Telemedicine Latency    | <500ms  | Direct WebSocket connection            |
| Wearable Sync           | <1 hour | Background job polling                 |
| Cache Hit Rate          | >80%    | Smart TTL policies                     |
| Database Query Latency  | <50ms   | Composite indexes                      |

### Scaling Strategies

**Horizontal Scaling**:

- Stateless API servers (3-10 instances)
- Auto-scaling based on CPU/memory
- Load balancer distributes traffic
- Session data in Redis (not in-memory)

**Database Scaling**:

- MongoDB replica set (3+ nodes)
- Read replicas for read-heavy queries
- Sharding for massive datasets

**Cache Scaling**:

- Redis master-replica setup
- Sentinel for automatic failover
- Cache warming strategy

**Background Job Scaling**:

- Multiple worker processes
- Bull queue for reliable processing
- Job retry with exponential backoff

### Optimization Techniques

1. **Database Indexing**:
   - Composite indexes on frequently queried fields
   - Sparse indexes for optional fields
   - TTL indexes for auto-expiring data

2. **Query Optimization**:
   - Projection (select only needed fields)
   - Pagination (limit result sets)
   - Aggregation pipelines for complex queries

3. **Caching**:
   - Cache layer for high-read data
   - TTL-based invalidation
   - Cache warming on startup

4. **Connection Pooling**:
   - MongoDB connection pool
   - Redis connection pool
   - HTTP keep-alive

5. **Compression**:
   - gzip response compression
   - Minified API responses

---

## Security & Compliance

### Security Layers

1. **Network Security**:
   - HTTPS/TLS only (ALB termination)
   - VPC with private subnets for databases
   - Security groups restricting access

2. **Authentication & Authorization**:
   - Google OAuth 2.0
   - JWT token with 30-min expiration
   - Refresh tokens (30-day validity)
   - RBAC middleware enforcement

3. **Data Security**:
   - Field-level encryption (SSN, medical data)
   - Database encryption at rest
   - Sensitive fields excluded from logs

4. **API Security**:
   - Rate limiting (per IP/user)
   - Input validation (Zod schemas)
   - CORS whitelist validation
   - Helmet security headers

5. **Audit & Compliance**:
   - Centralized audit logging
   - All health data access logged
   - HIPAA compliance (if required)
   - 30-day log retention

### Data Protection

**Encryption**:

- SSL/TLS in transit
- AES-256 at rest (sensitive fields)
- Encrypted database backups

**Access Control**:

- Role-based (user, admin, provider)
- Resource-level permissions
- Audit logging of access

**Compliance**:

- HIPAA (healthcare privacy)
- GDPR (EU privacy)
- CCPA (California privacy)
- SOC 2 (security framework)

---

## Monitoring & Observability

### Logging Strategy

**Structured Logging** (Winston):

- JSON format for log aggregation
- Levels: error, warn, info, debug
- Centralized logging to CloudWatch/ELK

**What to Log**:

- API requests/responses
- Database queries (slow query log)
- External API calls
- Errors with stack traces
- Audit events (medical data access)

### Monitoring

**Metrics to Track**:

- API response time (latency)
- Error rate & 5xx errors
- Request throughput (RPS)
- Database query latency
- Cache hit rate
- Background job success rate
- Memory/CPU usage
- Concurrent connections

**Alerting Thresholds**:

- API latency > 500ms (p95)
- Error rate > 1%
- Database latency > 200ms
- Memory usage > 80%
- Disk space < 10%
- Service downtime

### Observability Tools

- **Metrics**: CloudWatch, Prometheus
- **Logs**: CloudWatch Logs, ELK Stack
- **Traces**: DataDog APM, Jaeger
- **Error Tracking**: Sentry
- **Uptime**: StatusPage

---

## Architecture Highlights

✅ **Domain-Driven Design**: Services organized by business logic  
✅ **Scalable**: Horizontal scaling ready (stateless)  
✅ **Real-time**: WebSocket support for telemedicine  
✅ **Async Processing**: Bull queue for background jobs  
✅ **Multi-provider**: Adapter pattern for wearables  
✅ **Secure**: Encryption, RBAC, audit logging  
✅ **Observable**: Comprehensive logging & monitoring  
✅ **Reliable**: Error handling, retries, failover
