# GlucoSense AI

> AI-assisted glucose tracking, meal analysis, and diabetes-risk insights — built with Flutter, BLoC, Firebase, Supabase, and Google Gemini.

GlucoSense AI helps people living with (or at risk of) diabetes log their blood-glucose readings, analyse meals from a photo, predict their future risk profile, and stay on top of their routine through smart, OS-level reminders. Everything is wrapped in a feature-first clean architecture with full offline-aware sync.

---

## 📋 Table of contents

1. [Features](#-features)
2. [Tech stack](#-tech-stack)
3. [Architecture](#-architecture)
4. [Project structure](#-project-structure)
5. [Getting started](#-getting-started)
6. [Configuration](#-configuration)
7. [Notification system](#-notification-system)
8. [App flow](#-app-flow)
9. [Screen-by-screen guide](#-screen-by-screen-guide)
10. [Build & release](#-build--release)
11. [Troubleshooting](#-troubleshooting)

---

## ✨ Features

| Area | Capability |
|---|---|
| **Auth** | Email + password signup / login / password reset (Firebase Auth) |
| **Onboarding** | First-launch tour + guided medical-profile setup |
| **Glucose logging** | Log fasting / pre-meal / post-meal readings with meal tag, units, and timestamp |
| **Meal Predictor** | Snap a meal photo → Gemini analyses macros, glycaemic load, and suggests safer alternatives |
| **Saved meals** | Persist analysed meals so you can re-open them and re-log readings against them |
| **Risk Prediction** | AI-powered diabetes-risk score derived from the user's medical profile + recent logs |
| **Trends** | Charts and aggregates over time (7d / 30d / 90d) — TIR, average, variance, time-of-day patterns |
| **Reports** | Shareable summaries of readings + meals over a chosen date range |
| **Reminders** | Smart, OS-scheduled local reminders for fasting / breakfast / lunch / dinner / snacks, with deeplinking and "smart suppression" |
| **Profile** | Edit personal & medical data; preferences synced via Firestore |
| **Notifications history** | Local Hive log of every delivered notification, viewable in-app |

---

## 🛠 Tech stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (SDK ≥ 3.11.4) |
| **Language** | Dart |
| **State management** | `flutter_bloc` 9.x — Cubits + Blocs depending on complexity |
| **Backend (auth + DB + storage)** | Firebase (Auth, Cloud Firestore, Storage) |
| **Realtime / alt backend** | Supabase (`supabase_flutter`) |
| **AI** | Google Gemini via `google_generative_ai` |
| **Networking** | `dio` |
| **Navigation** | `go_router` (used in newer routes) |
| **Dependency injection** | `get_it` (light, only where needed; most repos are constructor-injected) |
| **Local storage** | Hive (notification history), SharedPreferences (session), Secure Storage (tokens) |
| **Notifications** | `flutter_local_notifications` 18.x + `flutter_timezone` + `timezone` |
| **UI** | Material 3, Google Fonts, `flutter_svg`, `cached_network_image` |
| **Permissions** | `permission_handler` |
| **Testing** | `flutter_test`, `bloc_test`, `mocktail` |

---

## 🎤 Presentation-ready summary

Use this section directly in your presentation or report.

### What we used to build this app

- **Mobile app:** Flutter + Dart
- **State management:** BLoC / Cubit (`flutter_bloc`)
- **Backend platform:** Firebase (Auth, Firestore, Storage)
- **Additional backend services:** Supabase
- **AI integration:** Google Gemini API (`google_generative_ai`)
- **Model serving API:** Flask API (used as a bridge between the app and ML model inference)
- **Networking:** Dio
- **Architecture:** Feature-first clean architecture (data / domain / presentation)

### AI and model integration statement

GlucoSense AI integrates a **Flask-based API layer** to connect the Flutter app with prediction logic, and uses the **Google Gemini API key (free tier)** to analyse meals and generate risk-oriented insights for users.

### Risk prediction statement (for slides)

We predict user risk from meal and profile context by combining:
- meal understanding (image + nutrition interpretation),
- medical profile and glucose history,
- AI inference delivered through Flask and Gemini-backed analysis.

### Tested statement (for presentation)

The system is tested end-to-end across:
- authentication and profile setup flow,
- glucose logging and history retrieval,
- meal analysis and AI response handling,
- risk prediction generation,
- reminder scheduling and notification delivery reliability.

---

## 🏗 Architecture

GlucoSense AI follows **feature-first clean architecture**. Every feature is self-contained and split into three layers:

```
lib/features/<feature>/
├── data/
│   ├── datasources/     # Firestore / Supabase / Gemini clients
│   ├── models/          # JSON-serialisable DTOs
│   └── repositories/    # Concrete repositories (implement domain contracts)
├── domain/
│   ├── entities/        # Pure Dart business objects (immutable, equatable)
│   └── repositories/    # Abstract contracts (no Flutter / no Firebase imports)
└── presentation/
    ├── cubit|bloc/      # State management
    ├── pages/           # Screens (route-level)
    └── widgets/         # Feature-scoped widgets
```

### Guiding rules

- **UI never talks to Firebase / Gemini directly.** Always: `Widget → Cubit/Bloc → Repository → DataSource → SDK`.
- **Domain layer has zero Flutter imports.** That keeps it testable, framework-free.
- **Data sources are swappable.** Each repository depends on an *abstract* data source so we can swap Firestore for Supabase (or a fake) without touching presentation.
- **State is explicit.** Every cubit/bloc emits states for `loading / success / empty / error` — no implicit nulls.
- **All async work has error handling.** No fire-and-forget futures in production paths.
- **Const constructors everywhere possible.** Widgets are small, composable, and reusable.

### Cross-cutting infrastructure (`lib/core/`)

```
lib/core/
├── colors/              # AppColors single source of truth
├── config/              # AppConfig + secrets
├── constants/           # App-wide constants
├── errors/              # Failure types
├── network/             # Dio client, interceptors
├── services/
│   ├── notification_service.dart      # Low-level notification engine
│   ├── reminder_scheduler.dart        # Domain-aware reminder orchestration
│   ├── notification_history/          # Hive-backed delivery log
│   ├── session_preferences.dart       # SharedPrefs wrapper
│   └── firebase_options.dart          # Generated by FlutterFire CLI
└── widgets/             # Reusable widgets (app bar, dialogs, scale scope, …)
```

---

## 📁 Project structure

```
lib/
├── main.dart                          # App entry — bootstraps Firebase, Hive, notifications
├── core/                              # Cross-cutting infrastructure
└── features/
    ├── auth/                          # Login, signup, forgot password
    ├── onboarding/                    # First-launch tour
    ├── profile_setup/                 # Initial medical profile capture
    ├── splash/                        # Branded launch screen + auth redirect
    ├── home/                          # Bottom-nav shell + Home tab
    ├── log_reading/                   # Glucose reading log + history
    ├── meal/                          # AI meal predictor + saved meals
    ├── risk_prediction/               # Gemini-based diabetes risk insights
    ├── trends/                        # Charts and aggregates
    ├── reports/                       # Date-range summaries
    ├── reminders/                     # User-configurable reminders
    └── profile/                       # View / edit medical & personal info

android/                               # Android-specific config (manifest, gradle)
ios/                                   # iOS-specific config (Podfile, Info.plist)
assets/                                # Image assets bundled with the app
```

---

## 🚀 Getting started

### Prerequisites

- Flutter SDK **≥ 3.11.4** (`flutter --version`)
- Dart **≥ 3.x**
- Android Studio / Xcode (for device emulation)
- A Firebase project (Auth + Firestore + Storage enabled)
- A Google AI Studio (Gemini) API key — [get one here](https://aistudio.google.com/apikey)

### Install

```bash
git clone <repo-url>
cd "GlucoSense AI"
flutter pub get
```

### Firebase setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication → Email/Password**, **Cloud Firestore**, and **Storage**.
3. Install the FlutterFire CLI and configure it:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This regenerates `lib/core/services/firebase_options.dart` for your project.

### Gemini API key

```bash
cp lib/core/config/secrets.example.dart lib/core/config/secrets.dart
```

Then open `lib/core/config/secrets.dart` and paste your key into `Secrets.geminiApiKey`. The file is already in `.gitignore`.

For CI / production, prefer:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

### Run

```bash
flutter run                         # debug on the default device
flutter run -d <device-id>          # specific device
flutter run --release               # release build on device
```

---

## 🔧 Configuration

| File | Purpose |
|---|---|
| `lib/core/services/firebase_options.dart` | Generated by FlutterFire CLI per environment. **Do not hand-edit.** |
| `lib/core/config/secrets.dart` | Gemini API key (gitignored). |
| `lib/core/config/app_config.dart` | App-wide config (env, feature flags). |
| `android/app/src/main/AndroidManifest.xml` | Android permissions + notification receivers. |
| `ios/Runner/Info.plist` | iOS permissions + display name. |

---

## 🔔 Notification system

This is one of the most carefully engineered parts of the app — refer to `lib/core/services/notification_service.dart` and `lib/core/services/reminder_scheduler.dart` for the implementation.

### Components

| Layer | File | Responsibility |
|---|---|---|
| Engine | `notification_service.dart` | Plugin init, channels, permissions, `showNow` / `scheduleAt` / cancel, history, diagnostics. |
| Orchestrator | `reminder_scheduler.dart` | Computes "next occurrence" times per slot, applies smart suppression, owns deeplink payloads, cancels reminders that the user has already logged. |
| History | `notification_history/` | Hive-backed log of delivered notifications surfaced in the Notifications screen. |
| UI | `features/reminders/...` | Settings screen + delivery-reliability banner with one-tap fixes and live test buttons. |

### Channels (Android)

Versioned channel IDs because Android **freezes channel settings on first creation** — bump the suffix when you change importance / sound / vibration:

| ID | Use |
|---|---|
| `glucosense_reminders_v2` | Fasting + general reminders |
| `glucosense_meals_v2` | Pre-/post-meal & snack reminders |
| `glucosense_hydration_v2` | Reserved for hydration |
| `glucosense_sleep_v2` | Reserved for sleep |

Legacy IDs (`reminders_channel`, `meal_channel`, etc.) are **deleted on init** so their stale silent settings can never override the new ones.

### Required AndroidManifest entries

Already declared in `android/app/src/main/AndroidManifest.xml`:

- Permissions: `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `VIBRATE`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- Receivers (required since `flutter_local_notifications` 16+):
  - `ScheduledNotificationReceiver` — receives the `AlarmManager` broadcast at scheduled time.
  - `ScheduledNotificationBootReceiver` — re-schedules pending notifications after reboot.

### Smart suppression

If the user has already logged a reading matching a reminder's slot within ±75 minutes, the reminder for that slot is **skipped on the next reschedule** to avoid pinging the user for something they already did. Implemented in `ReminderScheduler._isSuppressed()`.

### Deeplinks

Tapping a reminder pre-fills `LogReadingScreen` with the correct meal tag and reading type. The payload travels through:

```
NotificationService._onNotificationFired
  → ReminderScheduler.ingestTapPayload
  → ReminderScheduler.pendingTap (ValueNotifier)
  → LogReadingScreen listens & consumes
```

Cold-launch taps are also handled via `consumeLaunchPayload()` in `main.dart`.

### Diagnostics

Open **Reminders settings**. The banner at the top shows live status of:

- Notifications allowed (POST_NOTIFICATIONS)
- Exact alarm permission
- Battery-optimisation exemption

Two test buttons isolate failure modes:

- **Test now** — fires `showNow`. If this fails, the OS is blocking notifications outright.
- **Test 15s** — fires `scheduleAt`. If "Test now" works but this doesn't, scheduling / battery optimisation is the problem.

`NotificationService.diagnose()` dumps every relevant state (init flag, exact alarm, OS notifications, battery, channels, pending alarms) to the console.

---

## 🔁 App flow

```
SplashScreen
   │
   ▼
┌──────── User signed in? ────────┐
│                                 │
NO                                YES
│                                 │
▼                                 ▼
OnboardingOneScreen          ProfileSetupScreen?  ── completed ──▶ HomeShellScreen
   │                              │  (if profile incomplete)              │
OnboardingTwoScreen               │                                       │
   │                              ▼                                       ▼
   ▼                          HomeShellScreen                    [Home, Log, Meal,
LoginScreen / SignupScreen        │                               Risk, Profile]
                                  │
                                  └─▶ HomeShellScreen (5-tab bottom nav)
```

---

## 🖥 Screen-by-screen guide

### Auth
- **`SplashScreen`** — branded launch + token-based redirect.
- **`LoginScreen`** / **`SignupScreen`** / **`ForgotPasswordScreen`** — email/password flows backed by Firebase Auth.

### Onboarding
- **`OnboardingOneScreen`** + **`OnboardingTwoScreen`** — first-launch value-prop tour.
- **`ProfileSetupScreen`** — collects medical profile (age, sex, BMI, family history, etc.) used by Risk Prediction.

### Home shell (5 tabs)
- **Tab 0: `HomeTabScreen`** — daily summary, last reading, quick actions, latest meal analysis.
- **Tab 1: `LogReadingScreen`** — log a glucose reading. Listens for reminder deeplinks → pre-fills meal tag & reading type.
- **Tab 2: `MealPredictorScreen`** — pick / capture a photo, send to Gemini, get macros + glycaemic estimate + diabetic-friendly alternatives. Persists analysed meals.
- **Tab 3: `RiskPredictionScreen`** — AI-derived diabetes-risk explanation built from the user's medical profile + recent log patterns.
- **Tab 4: `ProfileScreen`** — view / edit personal & medical info; entry point to Reports, Trends, Reminders, and Notifications.

### Other screens
- **`RemindersSettingsScreen`** — toggle master switch, configure fasting / meal / snack times and active days; live reliability banner with one-tap fixes and test buttons.
- **`TrendsScreen`** — charts over 7 / 30 / 90 days with TIR, mean, range and time-of-day breakdown.
- **`ReportsScreen`** — date-ranged readings + meals summary, shareable.
- **`SavedMealDetailPage`** — re-opens a previously analysed meal.

---

## 🏗 Build & release

### Debug

```bash
flutter run
```

### Release APK (Android)

```bash
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

### Release App Bundle (Play Store)

```bash
flutter build appbundle --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
```

The Android build has `coreLibraryDesugaring` enabled (required by `flutter_local_notifications` 14+) — see `android/app/build.gradle.kts`.

### iOS

```bash
flutter build ios --release \
  --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
cd ios && pod install && cd ..
```

Then archive from Xcode for App Store distribution.

---

## 🐛 Troubleshooting

### "Test now" works but "Test 15s" doesn't

Make sure both broadcast receivers are present in `AndroidManifest.xml`:

```xml
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" android:exported="false" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
    </intent-filter>
</receiver>
```

Then `flutter clean && flutter run` (manifest changes don't apply on hot restart).

### Reminders fire on time when phone is awake but never fire after long Doze (Samsung / Xiaomi / Oppo / Vivo)

OEM battery managers kill scheduled alarms. Fix in **Reminders settings → Delivery banner → Fix**, or manually:

- Settings → Apps → GlucoSense AI → Battery → **Unrestricted**.
- Samsung: Settings → Battery → Background usage limits → **Never sleeping apps** → add GlucoSense AI.

### Gemini calls fail with `403` / `Permission denied`

- Verify your API key is set (`Secrets.geminiApiKey` or `--dart-define=GEMINI_API_KEY=...`).
- Make sure the Generative Language API is enabled for your Google Cloud project.

### Channel settings stuck at silent / low importance

Android freezes channel config on first creation. The codebase already handles this by versioning IDs (`*_v2`) and deleting legacy ones — if you ever change channel behavior, **bump the version suffix** in `notification_service.dart` (`remindersChannelId`, `mealsChannelId`, …) so a new channel is created.

### Build fails with "core library desugaring required"

Make sure `android/app/build.gradle.kts` has:

```kts
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## 📜 License

Proprietary — © 2026. All rights reserved.
