# Authentication & Token Persistence Architecture

This document breaks down the complete end-to-end authentication flow and token storage strategy implemented in the TAFS Parent Portal mobile app.

## The Dual-Storage Strategy

Mobile applications face a unique challenge: **Security vs. Speed**. 
* Reading from secure, encrypted storage (like the iOS Keychain) is asynchronous and takes time, causing a visible "loading" flash on app startup. 
* To solve this while keeping tokens secure, we implemented a **Dual-Storage Strategy**:

### 1. `flutter_secure_storage` (The Source of Truth)
This acts as the high-security vault for the user's data and tokens.
* **What it stores:** The complete `ParentDto` JSON string, which includes sensitive `accessToken` and `refreshToken`.
* **How it works:** It uses the `Keychain` on iOS and `EncryptedSharedPreferences` on Android.
* **Where it's used:** By the `AuthLocalDataSource` to permanently cache the user profile, and by the `TokenInterceptor` to attach the `Bearer` token to every outgoing network request.

### 2. `hydrated_bloc` (The UI State Cache)
This acts as the lightning-fast, synchronous state restorer for the UI.
* **What it stores:** The `AuthAuthenticated` BLoC state (which happens to include the Parent data). 
* **How it works:** It writes JSON to a standard, unencrypted local file in the device's temporary directory.
* **Where it's used:** It allows `AuthBloc` to instantly initialize in the `AuthAuthenticated` state *before* the first frame is even drawn on the screen. This entirely eliminates the need for splash screens or loading spinners when reopening the app.

---

## 🏗 Core Components

### 1. The Token Interceptor (`TokenInterceptor.dart`)
This is the silent workhorse of the app. It sits between the app and the backend, intercepting every HTTP request.
* **Automatic Attachment:** It transparently injects `Authorization: Bearer <accessToken>` into the headers.
* **Silent Refreshing:** If the backend returns a `401 Unauthorized` (meaning the token expired):
  1. It pauses all outgoing requests.
  2. It grabs the `refreshToken` from `flutter_secure_storage`.
  3. It hits the `/auth/refresh` endpoint on the backend.
  4. It saves the newly issued tokens back into secure storage.
  5. It resumes and retries the original failed requests.
  *(The user never even knows their token expired—they remain logged in seamlessly).*

### 2. The Root Router (`AuthGate.dart`)
`AuthGate` is the central traffic controller that owns all routing decisions, replacing traditional `Navigator.push` logic.
* **Instant Routing:** Because `hydrated_bloc` restores the `AuthAuthenticated` state instantly, `AuthGate` routes the user straight to the `MainDashboardPage` on app launch. No flash, no delay.
* **Reactive Student Selection:** It wraps both `AuthBloc` and `SelectedStudentCubit`. When a parent selects a student from the `StudentSelectionPage`, `AuthGate` detects the cubit change and automatically swaps the view to the Dashboard without manually pushing routes.

### 3. The Logout Mechanism
When the user clicks "Logout", three synchronized actions occur to ensure absolute security and clean UI state:
1. **Secure Wipe:** `AuthLocalDataSource.clearCache()` erases the tokens from iOS Keychain/Android Keystore.
2. **State Wipe:** `AuthBloc.clear()` commands `hydrated_bloc` to wipe the fast-access JSON cache from the disk.
3. **Route Purge:** `AuthGate` detects the state change to `AuthUnauthenticated` and fires `Navigator.popUntil()`. This forcefully closes any deep pages the user had open (like Fee Ledgers or Profile settings), revealing the `LoginPage` cleanly at the root.

---

## 🔄 The complete flow

1. **User enters credentials** -> `AuthRemoteDataSource` calls `/auth/login`.
2. Backend responds with `accessToken` and `refreshToken`.
3. `AuthRepository` saves these to `flutter_secure_storage`.
4. `AuthBloc` emits `AuthAuthenticated(parent)`.
5. `hydrated_bloc` intercepts this emission and caches the state to local disk.
6. `AuthGate` detects `AuthAuthenticated` -> Shows `StudentSelectionPage` or `MainDashboardPage`.
7. **User force-closes app and reopens later.**
8. App starts up. `hydrated_bloc` reads from disk and sets `AuthBloc` state to `AuthAuthenticated` instantly.
9. `AuthGate` sees `AuthAuthenticated` -> Shows Dashboard instantly.
10. Background polling timer on `FamilyProfilePage` occasionally fetches fresh parent data and updates both `secure_storage` and `hydrated_bloc` seamlessly.
