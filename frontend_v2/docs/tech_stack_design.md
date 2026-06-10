# HealthX Frontend (v2) Tech Stack & Design System Specification

This document defines the exact technology stack, architecture, theme, colors, typography, and iconography for the new `frontend_v2` mobile application.

---

## 1. Technology Stack

*   **Framework**: Flutter (targeting Android/iOS, building mobile APK).
*   **State Management**: `flutter_riverpod` (v2.x) combined with `riverpod_generator` for code generation and robust type safety.
*   **Routing**: `go_router` for declarative, link-based navigation.
*   **Networking / API**: `dio` (with interceptors for authentication, logging, and error handling).
*   **Local Storage**: `shared_preferences` or `hive` for persistent caching (e.g., user sessions, settings).
*   **JSON Serialization**: `freezed` and `json_serializable` for immutable data models.

---

## 2. Color Palette & Theme Configuration

The application implements a custom `ThemeData` structure to support clean switching between light and dark modes in the future. The theme configuration is mapped as follows:

| Token Name | Light Mode Value | Dark Mode Value (Future) | Usage |
| :--- | :--- | :--- | :--- |
| **Primary** | `#D4FF00` (Neon Lime) | `#D4FF00` (Neon Lime) | Call-to-actions, active indicators, highlights |
| **Secondary** | `#121212` (Off-Black) | `#FFFFFF` (White) | Primary text, main body background, dark elements |
| **Tertiary** | `#FFFFFF` (White) | `#1E1E1E` (Dark Grey) | Card backgrounds, surface overlays |
| **Neutral** | `#666666` (Medium Grey)| `#999999` (Light Grey) | Subtitles, captions, disabled borders, inactive icons |
| **Scaffold BG** | `#F7F7F7` (Light Gray) | `#121212` (Off-Black) | Screen base background |
| **Alert/Error** | `#FF3333` | `#FF4444` | Negative actions, validation failures |
| **Alert/Success**| `#00E676` | `#00E676` | Positive actions, green dots, status |

---

## 3. Typography Specification

To maintain a clean, readable, and premium aesthetic, we will use the **Inter** font family via the `google_fonts` package. 

### Font Configurations (Flutter TextStyle mappings)
*   **Display Large**: Font size `32`, bold, font weight `w800`, letter spacing `0.5`, color: Secondary. (For macro numbers, overall score, etc.)
*   **Heading Large**: Font size `24`, bold, font weight `w700`, color: Secondary. (For main page headings like "Today's Summary", "Good Morning")
*   **Heading Medium**: Font size `18`, semi-bold, font weight `w600`, color: Secondary. (For card section titles like "HEALTH RECORDS", "EXPERT GUIDANCE")
*   **Body Large**: Font size `16`, regular/medium, color: Secondary. (For general body texts)
*   **Body Medium**: Font size `14`, regular, color: Neutral. (For descriptive text, doctor details)
*   **Caption/Subtitle**: Font size `12`, bold, all-caps, letter spacing `1.2`, color: Neutral. (For card headers like "DAILY SCORE", "STEPS TRACKER")

---

## 4. Iconography Specification

We will standardise on the **Phosphor Icons** library using the `phosphor_flutter` package. Phosphor provides a clean, consistent, and premium outline aesthetic matching the mockup graphics.

### Standardized Icon Map
*   **Navigation**:
    *   *Home*: `PhosphorIcons.house` (or `PhosphorIcons.houseFill` when active)
    *   *Tracker*: `PhosphorIcons.chartLineUp` (or `PhosphorIcons.chartLineUpFill` when active)
    *   *Consults*: `PhosphorIcons.users` (or `PhosphorIcons.usersFill` when active)
    *   *Shop*: `PhosphorIcons.shoppingBag` (or `PhosphorIcons.shoppingBagFill` when active)
*   **Health Metrics**:
    *   *Steps*: `PhosphorIcons.footprints`
    *   *Sleep*: `PhosphorIcons.moon`
    *   *Hydration*: `PhosphorIcons.drop`
    *   *Glucose*: `PhosphorIcons.activity`
    *   *Macros / Calories*: `PhosphorIcons.egg` or `PhosphorIcons.forkKnife`
*   **Interface**:
    *   *Search*: `PhosphorIcons.magnifyingGlass`
    *   *Location Pin*: `PhosphorIcons.mapPin`
    *   *Chevron Right*: `PhosphorIcons.caretRight`
    *   *Chevron Left / Back*: `PhosphorIcons.caretLeft`
    *   *Notifications*: `PhosphorIcons.bell`
    *   *Profile Edit*: `PhosphorIcons.pencilSimple`
    *   *Logout*: `PhosphorIcons.signOut`
    *   *Add to Cart*: `PhosphorIcons.plus`
    *   *Cart FAB*: `PhosphorIcons.shoppingCart`
