# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Gym Management SaaS** platform built with Flutter (Dart) and Firebase. It supports multiple roles: gym members, staff, gym owners, and a super admin who manages all gyms in the system.

Firebase project ID: `gym-saas-b2851`

## Common Commands

### Main Flutter App
```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Lint and static analysis
flutter test             # Run tests
flutter build apk        # Build Android APK
flutter build web        # Build for Firebase Hosting
flutter build windows    # Build Windows desktop app
```

### Firebase Cloud Functions (`functions/`)
```bash
npm install                              # Install function dependencies
npm run serve                            # Start local emulator (functions only)
firebase emulators:start --only functions
npm run deploy                           # Deploy functions to production
npm run logs                             # Stream live function logs
```

### Firebase Deployment
```bash
firebase deploy --only functions         # Deploy Cloud Functions
firebase deploy --only hosting           # Deploy Flutter web build
firebase deploy                          # Deploy everything
```

## Architecture

This is a **monorepo** containing three separate applications sharing one Firebase backend:

```
saas/
├── lib/                  # Main Flutter app (members, staff, owners)
├── ssaas/                # Super Admin Flutter app (separate Flutter project)
├── functions/            # Firebase Cloud Functions (Node.js 22)
├── android/ ios/ windows/ macos/ web/   # Platform targets for main app
├── pubspec.yaml          # Main app Flutter dependencies
└── firebase.json         # Firebase hosting + functions config
```

### Authentication & Routing

`lib/auth/auth_wrapper.dart` is the central router. After login, it reads the user's `role` field from Firestore (`users/{uid}`) and routes to the appropriate screen:
- `owner` → `GymOwnerScreen`
- `staff` → `GymStaffScreen`
- `member` → `GymUserScreen`

The super admin app (`ssaas/`) is a **completely separate Flutter project** with its own `pubspec.yaml`, `main.dart`, and Firebase initialization. Run it independently from the `ssaas/` directory.

### Feature Organization (`lib/features/`)

- **`owner/`** — Dashboard for gym owners: manage members, view analytics, configure gym settings, oversee payments and attendance
- **`staff/`** — Staff portal: mark attendance via QR scan, record fee payments
- **`user/`** — Member portal: view attendance calendar, membership status, pay fees

### Shared Utilities (`lib/shared/`)

- `auth_wrapper.dart` — Role-based routing after login
- `gym_access_guard.dart` — Access control checks
- `gym_status_service.dart` — Gym active/suspended/blocked status
- `qr_scan.dart` — QR code scanner (uses `mobile_scanner`)
- `skeleton_loaders.dart` — Shimmer loading states
- `utils.dart` — Common utility functions

### Firestore Schema

```
users/{uid}
  - name, email, role (owner|staff|member), gymId, isVerified, contactNumber, createdAt

gyms/{gymId}
  - gymName, ownerUid, location, defaultFee
  - plan (Monthly|2 Months|6 Months)
  - status (active|suspended|blocked), isSaaSActive
  - depositAccounts (Array)
  - currentAttendanceQrToken, attendanceQrExpiresAt, attendanceQrLastGeneratedAt

gyms/{gymId}/members/{memberId}
  - uid, name, contactNumber, plan
  - currentFee, feeStatus (paid|unpaid|overdue), validUntil
  - createdBy, createdAt

gyms/{gymId}/payments/{paymentId}
  - memberId, amount, method (easypaisa|jazzcash|cash)
  - verified, status (pending|completed|failed)
  - transactionId, plan, validUntil

gyms/{gymId}/attendance/{attendanceId}
  - memberId, date (YYYY-MM-DD), markedBy, status (present|absent)
```

### QR Attendance System

Attendance is QR-based. The Cloud Function `rotateAttendanceQrDaily` (scheduled at midnight Asia/Karachi timezone via Pub/Sub) rotates the `currentAttendanceQrToken` on every gym document daily. Staff scan this token to mark attendance; stale tokens are rejected.

## Tech Stack

- **Flutter**: 3.6+ (main app), 3.10.7+ (ssaas)
- **State**: Firebase Firestore real-time listeners (no separate state management library)
- **Auth**: Firebase Authentication
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage (member photos, files)
- **Functions**: Node.js 22, Firebase Functions v6
- **PDF**: `pdf` + `printing` packages for generating receipts
- **QR**: `qr_flutter` (display) + `mobile_scanner` (scan)
- **UI**: Material 3, dark theme, `Colors.yellowAccent` as primary accent

## Design System

- **Theme**: Dark (`ThemeData.dark()`) with `useMaterial3: true`
- **Primary accent**: `Colors.yellowAccent` (yellow on dark background)
- **Loading states**: Use `shimmer` skeleton loaders from `lib/shared/skeleton_loaders.dart`
- **Calendar views**: `table_calendar` package for attendance history
