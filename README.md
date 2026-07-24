# Junaid Zaidi Library App

A Flutter app for the Junaid Zaidi Library at COMSATS University Islamabad. Students can browse library resources and spaces, read guides and rules, find the library on a map, register for an account, and log in. Library staff review and approve registrations through a separate web-based admin dashboard.

This is a Flutter port of an original Expo Router (React Native) app; several comments in the codebase point back at the `.js` file each screen mirrors.

This README is intentionally long — it's meant to be the one document that explains the whole system end to end, including the mistakes made and fixed along the way, so nobody has to reconstruct that history from git blame later.

---

## Table of Contents

1. [App structure](#app-structure)
2. [Design system](#design-system)
3. [Authentication — full architecture](#authentication--full-architecture)
4. [The complete request lifecycle](#the-complete-request-lifecycle)
5. [Firestore data model](#firestore-data-model)
6. [Firestore security rules](#firestore-security-rules)
7. [The admin dashboard — full setup and usage guide](#the-admin-dashboard--full-setup-and-usage-guide)
8. [Known gotchas and lessons learned](#known-gotchas-and-lessons-learned)
9. [Project setup (fresh clone)](#project-setup-fresh-clone)
10. [Repo layout](#repo-layout)
11. [Explicit replace-before-shipping checklist](#explicit-replace-before-shipping-checklist)
12. [Known limitations and open work](#known-limitations-and-open-work)

---

## App structure

Four bottom tabs, each mirroring an `app/(tabs)/*.js` route from the original:

| Tab | Screen | Status |
|---|---|---|
| Home | `home_screen.dart` | Hero banner, search box, resource shortcut grid |
| Library Resources | `library_resources_screen.dart` | Under construction (empty state) |
| Explore Spaces | `explore_spaces_screen.dart` | Under construction (empty state) |
| More | `more/more_screen.dart` | Live profile hero card + menu → Profile, Guides, Map, About |

Navigation is `IndexedStack` + `BottomNavigationBar` in `root_shell.dart`, so switching tabs preserves each tab's state. The **More** tab owns its own nested `Navigator` for its internal stack, with `PopScope` wired so Android's back button pops that inner stack before the outer app.

Three "More" menu items — Contact Us, Event Calendar, Junaid Zaidi Gallery — are intentionally inert and show a "Coming soon" badge. By design, not a bug.

The Map screen renders OpenStreetMap through `services/osm_map_html.dart` — an HTML string fed into `webview_flutter`, not a native map SDK.

## Design system

- `theme/tokens/` — spacing (`AppSpacing`), radius (`AppRadius`), typography (`AppTypography`), color primitives (`colors.dart`, includes `AppPalette` gradient scale)
- `theme/semantic/` — light/dark semantic color maps, accessed via `useTheme(context)`
- `widgets/ui.dart` — shared component barrel (`AppText`, `AppButton`, `AppTextField`, `Heading`, `AppCard`, `ScreenContainer`, `ListRow`, `AppAvatar`, `AppBadge`, etc.)

Brand color `#1D4ED8`. Font is Inter — real `.ttf` files bundled under a custom `Inter` family; `typography.dart` sets `fontFamily: 'Inter'` directly (an earlier version called `GoogleFonts.inter(...)`, which looked for fonts via the `google_fonts` package's own manifest instead of the bundled family — fixed).

Icons are **Lucide** (`flutter_lucide` package), migrated from `ionicons` app-wide. `ionicons` (last published 2023) defines `IoniconsData extends IconData`, which stopped compiling once Flutter marked `IconData` `final` — an unmaintained package hitting a framework breaking change with no fix coming.

---

## Authentication — full architecture

This app has gone through several real architecture changes during development, each one directed deliberately, not drifted into. This section describes the **current, final state** — see "Known gotchas" below for the history of how it got here.

### Three ways into the app

| Path | How it works | Real session? |
|---|---|---|
| **Email/password, Approved-gated** | Student signs up with email/password → verifies email → submits registration details → a librarian approves via the admin dashboard → student logs back in with that same email/password | Yes — Firebase Auth session, re-checked against Firestore's `status` field on every app boot |
| **Microsoft OAuth (Azure AD)** | *Built, not yet wired into any UI.* `FirebaseAuthService.signInWithMicrosoft()`, the `users` Firestore collection, and its security rules all exist and work; there is no button anywhere that calls it yet | Would be, once wired — domain-gated at sign-in, no approval step needed |
| **Guest** | "Continue as Guest" on the Welcome screen | No — browse-only, Profile and More tab's hero card both show a sign-in prompt instead of any data |

**Koha username/password login was removed** partway through development — it existed early on, matching an original spec where Firebase only verified email and Koha issued the real session. That spec changed: email/password itself became the real, persistent login once a librarian approves the request, which made a separate Koha "username" field nonsensical (students authenticate by email, not a librarian-assigned username). The **button and route are gone**; `koha_auth_service.dart`, `login_screen.dart`, and the Koha-session-check inside `AuthGate` are still present in the codebase (harmless — they just never trigger for any current user), left in rather than deleted since removal wasn't explicitly requested for the files themselves.

### AuthGate — the actual session decision

`lib/screens/auth/auth_gate.dart` is a four-state machine:

- **loading** — still checking on boot
- **authenticated** — a real session exists (Koha token in secure storage, OR a Firebase user whose linked `student_requests` document has `status: "Approved"`, OR a Firebase Microsoft user)
- **guest** — no account, but the guest flag is set in secure storage (persists across restarts, same as a real session — a guest isn't re-prompted through Welcome every launch)
- **signedOut** — none of the above; shows the Welcome flow

`FirebaseAuthService.hasApprovedRequestSession()` is what tells a Microsoft account and an email/password account apart, and re-validates the email/password case against Firestore on **every boot** — so if a librarian reverses an approval, that student is signed out automatically the next time they open the app, not left with a stale session.

### Logging out (and exiting guest mode)

`AuthScope` (`navigation/auth_scope.dart`) is an `InheritedWidget` that exposes `onLogout` and `isGuest` to everything inside `RootShell`. Calling `onLogout()` clears the Koha token, signs out of Firebase, and clears the guest flag — all three, unconditionally, since clearing a state that was never set is harmless. This single callback does double duty as "log out" for a real account and "exit guest mode / go sign in" for a guest.

### Profile data — one shared loader, not two copies

`ProfileScreen` and `MoreScreen`'s hero card both need "who is signed in and what do we know about them." Early on, `MoreScreen` used a hardcoded static placeholder (`data/student_profile.dart`) while `ProfileScreen` had its own real loading logic — which is exactly why the More tab kept showing "Student Name / FA00-BCS-000" long after Profile itself was showing real data correctly. Fixed by extracting `services/profile_loader.dart` (`ProfileLoader.load()` → `models/profile_data.dart`'s `ProfileData`) as the single shared source of truth. Both screens call the same loader now; they cannot drift apart again the way they did before.

---

## The complete request lifecycle

```
1. CREATE ACCOUNT              signup_email_screen.dart
   Email + password -> Firebase creates the account, sends a
   verification email. Client-side check: email must end with
   @isbstudent.comsats.edu.pk.
        |
        v
2. VERIFY EMAIL                 verify_email_screen.dart
   Student clicks the link in their inbox, returns, taps
   "I've verified" -> app calls user.reload().
        |
        v
3. SUBMIT REGISTRATION FORM     signup_form_screen.dart
   Full name, registration number, department, phone, CNIC
   (auto-formatted as xxxxx-xxxxxxx-x while typing).
   -> forces a fresh ID token (see Known Gotchas) before writing
   -> writes a document to Firestore's student_requests collection
   -> does NOT sign out anymore (this account is the real login now)
        |
        v
4. student_requests: Pending
        |
        v
5. LIBRARIAN REVIEWS            admin-dashboard.html (web)
   A staff member logs into the admin dashboard with a dedicated
   Firebase account, sees the request under the Pending tab, and
   clicks Approve or Reject.
        |
        +--- REJECTED ---------> student's future email/password
        |                        login attempts are correctly denied
        v
   APPROVED (status field set to exactly "Approved")
        |
        v
6. LOG IN                       login flow: "Log in with Email" on Welcome
   Student enters the SAME email/password they signed up with.
   FirebaseAuthService checks Firestore: status == Approved -> in.
        |
        v
7. APP UNLOCKED                 AuthGate flips to RootShell, live
```

Steps 1-3 and 6 are app code. Step 5 happens in a **separate web page** (the admin dashboard), not inside the mobile app — this was a deliberate choice: it keeps librarian-level Firestore write access out of the mobile client entirely, while still giving staff a real UI instead of hand-editing documents in the Firebase Console.

---

## Firestore data model

### `student_requests/{requestId}`

| Field | Type | Notes |
|---|---|---|
| `fullName` | string | |
| `registrationNumber` | string | e.g. `FA23-BCS-050` |
| `department` | string | |
| `email` | string | Must match the authenticated user's email at write time |
| `phone` | string | |
| `cnic` | string | Format `xxxxx-xxxxxxx-x` |
| `status` | string | Exactly one of `Pending`, `Approved`, `Rejected` — see warning below |
| `createdAt` | timestamp | Server-set via `FieldValue.serverTimestamp()` |

**The `status` field only ever recognizes those three exact values, case-sensitive.** It's set by hand in the Firebase Console early in development and now via the admin dashboard's buttons — either way, typing a fourth value (like `"Verified"`, a real mistake made once during this build) will silently fail to match any status-check branch in the code. Stick to the three exact values.

### `admins/{uid}`

A document existing at all, at a Firebase Auth UID as its document ID, means that account can access the admin dashboard and approve/reject requests. Document content doesn't matter (a single placeholder field like `role: "librarian"` is enough) — only existence matters. Nothing can write to this collection from any client; adding an admin is always a manual Firebase Console step.

### `users/{uid}`

Built for the (not-yet-wired) Microsoft OAuth path. One document per Firebase uid, containing `fullName`, `registrationNumber`, `department`, `email`, `phone`, `cnic` — no `status` field, since a successful Microsoft sign-in against COMSATS' tenant is itself the approval.

---

## Firestore security rules

Current `firestore.rules` (also in the repo root):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /admins/{adminId} {
      allow read: if request.auth != null && request.auth.uid == adminId;
      allow write: if false;
    }

    match /student_requests/{requestId} {
      allow create: if request.auth != null
                    && request.auth.token.email_verified == true
                    && request.resource.data.email == request.auth.token.email
                    && request.resource.data.status == 'Pending';

      allow read: if request.auth != null
                  && (resource.data.email == request.auth.token.email
                      || exists(/databases/$(database)/documents/admins/$(request.auth.uid)));

      allow update: if request.auth != null
                    && exists(/databases/$(database)/documents/admins/$(request.auth.uid))
                    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['status']);

      allow delete: if false;
    }

    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow create: if request.auth != null
                    && request.auth.uid == userId
                    && request.auth.token.email.matches('.*@isbstudent[.]comsats[.]edu[.]pk$');
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }
  }
}
```

Key design points:
- A student can only create/read their **own** request (email match against the auth token).
- Admins can read every request, but can update **only the `status` field** — the `hasOnly(['status'])` check means even an admin account can't silently rewrite a student's name/CNIC through the dashboard.
- Nobody can delete a request from the client, ever.

Two composite indexes are required for the queries this app actually runs (Firestore doesn't auto-create these — see `firestore.indexes.json`):

```json
{
  "indexes": [
    {
      "collectionGroup": "student_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "email", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "student_requests",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```
Deploy with `firebase deploy --only firestore:indexes`.

---

## The admin dashboard — full setup and usage guide

`admin-dashboard.html`, in the project root, is a **single self-contained HTML file** — no build step, no npm, no separate project. It uses the Firebase JS SDK loaded from a CDN. It exists so library staff can review and approve/reject registration requests without needing Flutter, without needing access to the Firebase Console directly, and without any librarian-level access ever being shipped inside the mobile app itself.

### What it looks like

- A login screen (brand-blue "JZ" mark, email/password fields) — this is a **separate Firebase account** from any student account, dedicated to admin access.
- Once logged in, a real-time list of registration requests with four tabs: **Pending**, **Approved**, **Rejected**, **All**.
- Each request shows every field submitted (name, registration number, department, email, phone, CNIC, submission time) plus **Approve**/**Reject** buttons on Pending items.
- Updates are live — approving a request removes it from Pending and it appears under Approved immediately, no manual refresh.

### One-time setup

**Step 1 — Create the admin login account.**
Firebase Console → your project → **Authentication** → **Users** tab → **Add user**. Email can be anything (doesn't need to be a real/COMSATS address) — pick a real password, since this genuinely guards access to every student's personal data. After creating it, click into the new user row and copy the **User UID** (a long string like `t5VfEs2ud5UDCtBRwA2ksHPcZu63`).

**Step 2 — Grant that account admin access.**
Firestore Database → **Data** tab → **Start collection** → Collection ID: `admins` (exact lowercase) → Document ID: **paste the UID from Step 1**, don't let it auto-generate one → add any single field (e.g. `role: "librarian"`, content doesn't matter) → **Save**.

**Step 3 — Fill in the dashboard's Firebase config.**
Open `lib/firebase_options.dart`, find the `web` block, and copy `apiKey`, `appId`, `messagingSenderId`, and `storageBucket` into the matching `REPLACE_ME` placeholders inside `admin-dashboard.html`'s `<script>` tag. (`authDomain` and `projectId` are already correct — they follow a predictable pattern from the project ID.) This is not secret data; the same config already ships inside every copy of the mobile app.

**Step 4 — Serve it over a real HTTP origin. Do NOT open it by double-clicking the file.**
This is the single most important setup step, worth its own callout:

> **`file://` origins genuinely do not work correctly with Firebase's SDKs.** Firebase Auth and Firestore both rely on browser mechanisms (IndexedDB persistence, iframe coordination) that need a stable origin — `file://` pages get treated as unique, isolated origins essentially every load. During development this manifested as a deeply confusing, persistent "query requires an index" error that kept reappearing verbatim no matter what was actually fixed (the file's content, the Firestore indexes, browser cache) — because the error text on screen was stale/stuck DOM content from an underlying Firebase initialization failure, not a live, current server response. It cost significant debugging time before the real cause (the `file://` origin itself) was identified. **Always serve this file over `http://`, even for local testing.**

```powershell
cd path\to\project\root
python -m http.server 8000
```
Leave that terminal running, then open `http://localhost:8000/admin-dashboard.html` in your browser — never open the `.html` file directly from File Explorer.

For anything beyond quick local testing, host it properly via Firebase Hosting instead of a throwaway local server:
```powershell
firebase init hosting
firebase deploy --only hosting
```

### Day-to-day usage

1. Open the dashboard's real URL (localhost during dev, or your Hosting URL once deployed).
2. Log in with the admin account from Step 1.
3. **Pending** tab shows new requests as they come in (real-time, no refresh needed).
4. Review the student's details, click **Approve** or **Reject**.
5. The student can now log in (if approved) via "Log in with Email" on the app's Welcome screen, using the same email/password they signed up with.

### Adding more admins

There's no "invite an admin" button — creating a new admin is always Steps 1-2 above, repeated. This is intentional: granting elevated access is never something the client (or the dashboard itself) can do to itself.

---

## Known gotchas and lessons learned

Recorded here so the same debugging time doesn't get spent twice.

**PowerShell's `-Encoding UTF8` writes a byte-order mark (BOM).** Dart's compiler tolerates it silently; Firestore's rules compiler does not (`token recognition error at: '﻿'`). Fix: write files via `[System.IO.File]::WriteAllText(path, content, [System.Text.UTF8Encoding]::new($false))` instead of `Set-Content -Encoding UTF8`, which is what every file-write command in this project's history now uses.

**Special characters (em dashes, `§`, etc.) can get silently mangled when pasted into a misconfigured terminal**, producing mojibake like `â€"` baked permanently into the file — not a display bug, genuinely corrupted content. `admin-dashboard.html` had this happen to it once. The practical fix adopted here: avoid non-ASCII characters entirely in files that get written via terminal paste, using plain hyphens instead of em dashes throughout.

**Firestore composite indexes are required for any query combining an equality/range filter with an `orderBy` on a different field**, and are not auto-created. Every distinct field combination needs its own index — `email`+`createdAt` and `status`+`createdAt` are two separate indexes in this project, not one. An unhandled `FAILED_PRECONDITION` from a missing index, if not caught, can hang an app in a loading state forever (this happened to `AuthGate`'s boot-time session check) — `FirebaseAuthService.hasApprovedRequestSession()` now wraps that call in try/catch specifically to fail safe instead.

**`file://` origins break Firebase's SDKs in confusing, hard-to-diagnose ways.** See the admin dashboard section above — always serve over real HTTP, even locally.

**PowerShell command blocks are sometimes skipped when pasting a long sequence of multiple blocks** — several rounds of "this file doesn't exist" or "this import is missing" during this build traced back to a specific `Set-Content`/`WriteAllText` block simply never having been run, not a bug in the code or logic. Worth double-checking with a targeted `Select-String` (or `Test-Path`) after any multi-block delivery, rather than assuming every block executed.

---

## Project setup (fresh clone)

```powershell
git clone https://github.com/MuaazTasawar/junaid-zaidi-library-app.git
cd junaid-zaidi-library-app
flutter pub get
```

You'll also need:
- `android/app/google-services.json` — committed to this repo (environment config, not a secret).
- A Firebase project with Email/Password sign-in enabled, both composite indexes deployed, and rules deployed — see the Firestore sections above.
- `admin-dashboard.html` configured per the setup guide above, if you need approval capability.

```powershell
flutter run
```

## Repo layout

```
lib/
├── main.dart                        App entry, Firebase init, theme setup
├── firebase_options.dart            Generated by flutterfire CLI (android + web)
├── config/
│   └── api_constants.dart           Koha URL (unused now, see below), Azure tenant ID, Firestore collection names
├── models/
│   ├── student_request.dart         student_requests document shape
│   ├── app_user.dart                users document shape (Microsoft path)
│   └── profile_data.dart            Shared "who's signed in" shape
├── services/
│   ├── firebase_auth_service.dart   Email verify + Approved-gated login + Microsoft OAuth (unwired)
│   ├── firestore_service.dart       student_requests + users CRUD
│   ├── koha_auth_service.dart       Unused in UI — kept, not deleted
│   ├── secure_storage_service.dart  Koha token (unused) + guest-mode flag
│   └── profile_loader.dart          Shared profile-loading logic (ProfileScreen + MoreScreen)
├── navigation/
│   ├── routes.dart                  AuthRoutes + MoreRoutes
│   └── auth_scope.dart              InheritedWidget: onLogout + isGuest
├── theme/ , widgets/                 Design tokens + shared UI primitives
└── screens/
    ├── root_shell.dart
    ├── home_screen.dart / library_resources_screen.dart / explore_spaces_screen.dart
    ├── more/                        Profile (real data), Guides, Map, About
    └── auth/                        AuthGate, Welcome, Signup (email → verify → form), EmailLogin
                                      (login_screen.dart / Koha screen present but unlinked)

admin-dashboard.html                 Standalone web admin tool — see dedicated section above
firestore.rules / firestore.indexes.json
mock-koha-server.js                  Dev-only, delete before shipping if still present
```

## Explicit replace-before-shipping checklist

| Item | Location | Action |
|---|---|---|
| Hardcoded dev login (`testuser`/`test1234`) | `lib/services/koha_auth_service.dart` | Remove the `_devUsername`/`_devPassword` check entirely |
| Mock Koha server | `mock-koha-server.js` (project root, if still present) | Delete |
| Azure tenant ID | `lib/config/api_constants.dart` → `azureTenantId` | Confirm this is genuinely COMSATS' tenant — it was taken from a sample payload, never explicitly stated as authoritative |
| Admin dashboard hosting | `admin-dashboard.html` | Move off a local `python -m http.server` onto real Firebase Hosting before any real staff member relies on it day to day |
| Koha files | `koha_auth_service.dart`, `login_screen.dart` | Decide: delete entirely, or leave as dormant/future capability |
| Microsoft OAuth | Welcome screen, onboarding flow | Not wired to any UI — either finish wiring it in, or remove the unused service/model/rules if it's genuinely not needed |

## Known limitations and open work

- **Microsoft OAuth has no UI path** — see above.
- **No automated Koha provisioning** — moot now that Koha login is unlinked, but the service code still exists.
- **iOS not targeted** — only `android/` and `web/` platform folders exist in the repo.
- **Library Resources / Explore Spaces tabs** — still placeholder empty states, unrelated to auth.
- **Admin dashboard has no audit trail** — approving/rejecting doesn't record which admin did it or when (beyond Firestore's own document history if you dig for it). Would need a small schema addition (`reviewedBy`, `reviewedAt` fields) if that matters going forward.