# **TAFS - Flutter Engineering Standards & Coding Guidelines**

**Version:** 1.0

**Context:** School ERP (Parent & Student Mobile Portal) 

**Core Stack:** Flutter (Mobile), NestJS (Backend), AWS (Infrastructure) 

---

## 1. Architectural Principles

### 1.1 "Feature-First" Layering

We do not organize by layer (e.g., `controllers`, `views`); we organize by **feature**. This allows for a modular approach where each school capability is self-contained and aligns with our **Modular Monolith** backend.

**Directory Structure:**

```text
lib/
├── core/                   # Shared logic (Network, Auth, Utils, Design System)
├── features/
[cite_start]│   ├── auth/               # Per-Student Login Logic [cite: 214]
[cite_start]│   ├── admission/          # Admission status & Form tracking [cite: 201, 204]
[cite_start]│   ├── finance/            # Live Ledger, Challan Downloads, & Installments [cite: 207, 211, 214]
[cite_start]│   └── profile/            # Academic Snapshot (Campus, Grade, Section) [cite: 215]
└── main.dart

```

### 1.2 Strict Separation of Concerns

* **UI Layer:** Dumb widgets only. No business logic allowed.
* **BLoC Layer:** Handles state changes and user events (e.g., switching between sibling profiles).
* **Domain Layer:** Pure Dart code (Entities & Use Cases). No Flutter dependencies.
* 
**Data Layer:** Handles API calls (NestJS) and local caching.



---

## 2. Dart & Flutter Style Guide

### 2.1 Strong Typing & Null Safety

* **Prohibited:** `dynamic` types are strictly forbidden unless handling raw JSON in the Data Layer.
* **Required:** Explicitly define return types for all functions and arguments.
* 
**Rationale:** Financial applications cannot tolerate runtime type errors.



### 2.2 Const Correctness

* Use `const` constructors for widgets and variables wherever possible to improve performance and reduce garbage collection on lower-end devices.

---

## 3. State Management (BLoC Pattern)

We use the BLoC (Business Logic Component) pattern to manage complex data flows, such as handling partial payments and multi-month credits.

### 3.1 Event-Driven Architecture

* **Events:** Must extend `Equatable` to ensure distinct events are processed correctly.
* **Naming:** `[Feature][Action][Status]` (e.g., `FinanceChallanDownloadSuccess`, `AuthStudentLoginStarted`).

### 3.2 State Immutability

* States must be immutable. Use `copyWith` patterns to update state.
* **Do not** mutate variables inside a BLoC; always yield a new state.

---

## 4. Security & "Zero Trust" Coding

### 4.1 Sensitive Data Handling

* **Secrets:** Never hardcode API keys or URLs. Use `flutter_dotenv` or compile-time variables.
* **Storage:** Per-student JWTs and Session Tokens must **only** be stored in `FlutterSecureStorage`.

### 4.2 Logging & PII (Personally Identifiable Information)

* **Redacted Logging:** When logging errors, redact PII such as student names, GR numbers, or parent CNICs.

---

## 5. UI & Widget Guidelines

### 5.1 Reusable Components

* Common elements (Fee Status Badges, Challan List Cards, Push Notification Banners) must be extracted to `lib/core/widgets`.

### 5.2 Accessibility & Offline Readiness

* **Touch Targets:** All buttons must be at least 44x44 dp.
* 
**Offline First:** The app must implement local caching so parents can view the last-synced ledger even during internet instability.



---

## 6. Repository Pattern & Data Flow

### 6.1 DTOs vs. Entities

* The **Data Layer** must use DTOs (e.g., `ChallanDto`) to parse JSON from the NestJS backend.
* The **Domain Layer** must use Entities (e.g., `Challan`).
* Repositories are responsible for mapping `DTO -> Entity`.

### 6.2 Error Handling

* Catch specific exceptions (e.g., `DioException`).
* Return `Either<Failure, Type>` (using `dartz`) instead of throwing exceptions to the UI.