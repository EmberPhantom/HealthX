# HealthX Backend Audit Report: OAuth Implementation Phase

This report provides a detailed overview of the technologies, architecture, and security practices implemented during the integration of Google OAuth 2.0 into the HealthX backend.

## 1. Technology Stack

The implementation utilizes a modern, typed, and scalable stack:

| Component        | Technology               | Version | Purpose                                       |
| ---------------- | ------------------------ | ------- | --------------------------------------------- |
| **Runtime**      | Node.js                  | Latest  | Core server environment                       |
| **Language**     | TypeScript               | 6.0+    | Strong typing and enhanced maintainability    |
| **Framework**    | Express.js               | 5.2+    | Robust routing and middleware management      |
| **Database**     | MongoDB (Mongoose)       | 9.4+    | NoSQL data persistence                        |
| **Authentication**| Passport.js              | 0.7+    | Industry-standard authentication middleware  |
| **Security**     | Helmet, CORS             | Latest  | HTTP header security and origin control       |
| **Tokens**       | JSON Web Tokens (JWT)    | 9.0+    | Stateless identity management                 |
| **Validation**   | Zod                      | 4.3+    | Schema-based input validation (found in deps) |

## 2. Architectural Patterns

### 2.1 Implementation Logic: "Identify & Link"
The authentication flow is designed to be user-centric and flexible:
1.  **Google ID Search**: First, we check if the `googleId` exists to provide the fastest login path.
2.  **Email-Based Linking**: If no `googleId` is found, we search by `email`. If an account exists, we append the `googleId` and update the avatar, effectively "claiming" the account for OAuth without manual intervention.
3.  **Just-In-Time Provisioning**: If no account exists, a new skeleton profile is created instantly using Google Profile data.

### 2.2 Stateless Session Management
We opted for **JWT-based authentication** over Express sessions to support the mobile application requirement:
-   **Reduced Server Overhead**: No session store (Redis/Mongo) required forauth state.
-   **Mobile Integration**: JWTs are passed via deep links, allowing the mobile app to store them in secure storage (e.g., Keychain/EncryptedSharedPreferences).

### 2.3 Modular Structure
The code follows a clean separation of concerns:
-   `src/config/passport.ts`: Strategy definitions.
-   `src/models/User.ts`: Data schema and indexing.
-   `src/controllers/auth.controller.ts`: Business logic and token issuance.
-   `src/routes/auth.routes.ts`: Endpoint definitions.

## 3. Security Hardening

> [!IMPORTANT]
> **Data Integrity**: The `googleId` field in MongoDB is configured with `sparse: true` and `unique: true`. This ensures that multiple users without a Google ID can co-exist (standard users), but no two users can share the same Google identity.

-   **JWT Security**: Tokens are signed with a strong secret and have a short expiration (30 minutes) to minimize the impact of token leakage.
-   **Header Protection**: `helmet` is used to set security headers, mitigating common attacks like Clickjacking and XSS.
-   **Safe Deserialization**: Passport's deserialization logic uses `Mongoose` to fetch users by ID, ensuring only valid, existing users are attached to requests.
-   **Environment Separation**: All sensitive credentials (Client IDs, Secrets) are strictly managed via `.env` and never hardcoded.

## 4. Frontend & UX Integration

### 4.1 Aesthetic Landing Page
A dedicated root view (`src/views/index.html`) was created with:
-   **Modern Aesthetics**: Glassmorphism effects, gradient typography, and a "System Online" heartbeat animation.
-   **Mobile Optimization**: Responsive layout that scales perfectly on handheld devices.

### 4.2 Deep Linking
The callback mechanism is pre-configured for mobile consumption:
-   **Redirect URI**: Supports `healthx://auth` (customizable).
-   **Token Delivery**: Tokens are appended as query parameters for immediate interception by the mobile OS.

---

## 5. Future Roadmap Recommendations

1.  **Refresh Tokens**: Implement a refresh token rotation strategy for longer mobile sessions.
2.  **OAuth Expansion**: Add Facebook and X (Twitter) strategies using the established "Identify & Link" pattern.
3.  **Profile Completion**: Implement a post-OAuth "Onboarding" route to collect additional health-specific data from the user.
