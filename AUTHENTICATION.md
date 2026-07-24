# Authentication — how it actually works

This is the deep-dive companion to the main README. Read this before touching anything under `lib/screens/auth/`, `lib/services/`, or `firestore.rules`.

## The one rule that explains everything else

**Two separate systems, two separate jobs, and they never talk to each other automatically:**

| System | Job | Never does |
|---|---|---|
| **Firebase Auth** | Proves a student controls their email, during sign-up only | Issue the real app session |
| **Koha** | The actual login (`POST /api/v1/auth/password`), the real session | Get touched during sign-up |

If you remember nothing else from this document: **approving a Firestore document does not create a Koha account.** They are two completely disconnected systems, bridged only by a human being reading a Firestore document and manually typing details into Koha's own admin panel. This is by design (per the original spec), not a missing feature.

## Full flow, start to finish

```
1. CREATE ACCOUNT           signup_email_screen.dart
   Email + password -> Firebase creates a TEMPORARY account
                        -> sendEmailVerification() fires
        |
        v
2. VERIFY EMAIL              verify_email_screen.dart
   Student clicks the link in their inbox (outside the app)
   Taps "I've verified" -> app calls user.reload()
        |
        v
3. SUBMIT REGISTRATION FORM  signup_form_screen.dart
   Full name, reg number, department, phone
   -> forces a fresh ID token (see "The token gotcha" below)
   -> writes a document to Firestore's student_requests collection
   -> signs OUT of the temporary Firebase account (Firebase's job is done)
        |
        v
4. student_requests: Pending      <- sitting in Firestore, nobody has looked at it yet
        |
        v
5. LIBRARIAN REVIEWS          Firebase Console, by hand, outside this app
   Firestore -> student_requests -> open the document -> read the details
        |
        +--- REJECTED --------------------> dead end, nothing else happens
        |
        v
   APPROVED (change status field to exactly "Approved")
        |
        v
6. KOHA PATRON CREATED        Koha's own staff interface, by hand, outside this app
   Someone with Koha admin access goes to Patrons -> New patron,
   manually re-types the details from the Firestore document,
   and Koha assigns (or lets them set) a real username + password.
   *** THIS STEP HAS NO CODE. Nothing in this repo does it for you. ***
        |
        v
7. LOG IN                     login_screen.dart
   Student enters the Koha username/password from step 6
   -> POST /api/v1/auth/password, straight to Koha, never through Firebase
        |
        v
8. APP UNLOCKED                RootShell loads, AuthGate flips over live
```

Steps 1-3 and 7 are the only ones with actual app code. Steps 5 and 6 are 100% manual, human, outside-the-app actions — that's the biggest thing people get confused about the first time they test this end to end.

## The files, in the order the flow touches them

| Step | File |
|---|---|
| 1, 2 | `services/firebase_auth_service.dart` |
| 3 | `services/firestore_service.dart`, `models/student_request.dart` |
| — | `firestore.rules` (server-side gatekeeper for step 3's write) |
| 7 | `services/koha_auth_service.dart` |
| all | `services/secure_storage_service.dart` (stores the Koha token from step 7) |
| routing | `screens/auth/auth_gate.dart` — decides Welcome-flow vs `RootShell` based on whether a Koha token exists |
| logging out | `navigation/auth_scope.dart` — lets `ProfileScreen` (deep inside `RootShell`) tell `AuthGate` to clear the session and flip back |

## Gotcha #1: the stale-token / permission-denied bug

**Symptom:** step 3's Firestore write fails with:
```
[cloud_firestore/permission-denied] PERMISSION_DENIED: Missing or insufficient permissions.
```
...even though the student genuinely did click the verification link and the app correctly shows them as verified.

**Why:** `firestore.rules` checks `request.auth.token.email_verified == true`. That reads a claim baked into the *cached ID token* — set once, when the temporary Firebase account was first created (back in step 1, before verification happened). Step 2's `user.reload()` correctly updates the client-side `User.emailVerified` flag (which is why the app *shows* the student as verified) — but `reload()` does **not** force a fresh ID token. Firestore still receives the old token, where the claim is `false`, and correctly rejects the write. This is a well-known Firebase gotcha, not a bug in the rules themselves.

**Fix (already applied):** `signup_form_screen.dart`'s `_handleSubmit()` calls `user.getIdToken(true)` — forcing a fresh token with the updated claim — immediately before the Firestore write:
```dart
await user!.getIdToken(true);
```
If you ever see this exact error again, this line is the first thing to check hasn't been accidentally removed.

## Gotcha #2: two different "email_verified" states

Don't confuse:
- `FirebaseAuthService.isEmailVerified` — reads the **client-side** `User.emailVerified` flag. Updated by `user.reload()`. This is what the app's own logic checks before letting a student proceed to the registration form.
- The **ID token's** `email_verified` claim — what Firestore's security rules actually see. Only refreshed by `getIdToken(true)`.

They can disagree for a short window (exactly the situation Gotcha #1 describes). If you ever add a new Firestore write anywhere in the auth flow, force a fresh token first — don't assume `isEmailVerified` being `true` means the token agrees.

## Testing without a real Koha server

If you don't have a real Koha instance URL yet, you can still exercise the entire login code path — real HTTP request, real headers, real timeout, real error branches — using a throwaway local mock server instead of stubbing the code.

**1. Create the mock server** (lives at the project root, not inside `lib/` — it's a dev tool, not part of the app):

```powershell
notepad mock-koha-server.js
```
```javascript
const http = require('http');
const { URLSearchParams } = require('url');

const TEST_USERNAME = 'teststudent';
const TEST_PASSWORD = 'test1234';

const server = http.createServer((req, res) => {
  if (req.method !== 'POST' || req.url !== '/api/v1/auth/password') {
    res.writeHead(404);
    res.end();
    return;
  }

  let body = '';
  req.on('data', chunk => (body += chunk));
  req.on('end', () => {
    const params = new URLSearchParams(body);
    const userid = params.get('userid');
    const password = params.get('password');

    console.log(`Login attempt: userid=${userid}`);

    if (userid === TEST_USERNAME && password === TEST_PASSWORD) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ access_token: 'mock-token-123', patron_id: '1001' }));
    } else {
      res.writeHead(401, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Invalid credentials' }));
    }
  });
});

server.listen(8080, '0.0.0.0', () => {
  console.log('Mock Koha server running on port 8080');
});
```
```powershell
node mock-koha-server.js
```
Leave that terminal running.

**2. Find your PC's actual LAN IP** — your phone can't reach `localhost` on your PC, it needs your PC's real network address:
```powershell
ipconfig
```
Look under your active **Wi-Fi** adapter specifically — ignore any Hyper-V/VMware virtual adapters (`172.17.x.x`, `192.168.118.x`, `192.168.32.x` are common virtual-adapter ranges; your phone has no route to those). You want something like `192.168.1.x`. Your phone and PC must be on the **same Wi-Fi network** (not mobile data).

**3. Sanity-check reachability before touching Flutter** — this rules out a firewall problem before you waste time debugging code:
- Open your phone's browser, go to `http://<your-pc-ip>:8080`. You should get *some* response (a 404 is fine — the server only handles `POST /api/v1/auth/password`). A timeout means Windows Firewall or router client-isolation is blocking it — go to Windows Firewall → Allow an app through firewall → Node.js → check "Private".

**4. Point the app at it** — ⚠️ **replace `192.168.1.X` below with your own IP from step 2**:
```powershell
notepad lib\config\api_constants.dart
```
```dart
// TEMP — local mock server for testing before the real Koha URL is
// provided. Swap back before shipping — search this file for this comment.
static const String kohaBaseUrl = 'http://192.168.1.X:8080';
```

**5. Test:**
```powershell
flutter run
```
Log in with `teststudent` / `test1234` → should succeed, land on `RootShell`. Anything else → "Incorrect username or password." Watch the `node mock-koha-server.js` terminal — it prints every attempted username.

**What this does and doesn't prove:** it validates the login screen's plumbing — request shape, error branches, token storage. It says **nothing** about whether the real Koha response actually uses `access_token`/`patron_id` as field names — that's still unverified until you test against the real instance.

**Before shipping:** delete `mock-koha-server.js` and put the real URL back in `api_constants.dart`. It should never ship.

## Getting real credentials once you have a real Koha URL

Two completely separate "credentials" exist and people regularly conflate them:

- **Mock server credentials** (`teststudent` / `test1234`) — hardcoded in `mock-koha-server.js`, has nothing to do with Firestore at all.
- **Real Koha credentials** — only exist after someone with Koha admin access manually creates a patron record (Patrons → New patron in Koha's staff UI), using the approved Firestore document's details as reference. Koha assigns/lets you set the real username and password at that point. Firestore's `Approved` status is the human decision that this *should* happen — it does not cause it to happen.

## Explicit replace-this-before-it-works checklist

Grep for these, or just check each one:

| What | Where | Current value | Replace with |
|---|---|---|---|
| Koha base URL | `lib/config/api_constants.dart` → `kohaBaseUrl` | `https://REPLACE_WITH_YOUR_KOHA_URL` (placeholder) or your mock server IP | Your real Koha instance's base URL, no trailing slash |
| Koha response field names | `lib/services/koha_auth_service.dart` → `login()` | Assumes `access_token`/`token` and `patron_id`/`borrowernumber` | Whatever your real Koha instance's `/api/v1/auth/password` actually returns — test once, adjust if the first real login throws "Unexpected response from the library server." |
| Firestore status value | Firebase Console, by hand | Must be exactly `Pending`, `Approved`, or `Rejected` | Nothing to "replace" in code — just don't type a fourth value like `"Verified"` by mistake; `StudentRequestStatus` in `models/student_request.dart` only recognizes those three, case-sensitive |
| Mock server file | `mock-koha-server.js` (project root) | Exists for local testing | Delete entirely before shipping |

## Logging out

`AuthGate` exposes a logout callback to everything inside `RootShell` via `AuthScope` (`navigation/auth_scope.dart`), the same `InheritedWidget` pattern the app already uses for cross-tab navigation (`app_tab_scope.dart`). `ProfileScreen`'s Log Out button calls:
```dart
await AuthScope.of(context).onLogout();
```
which clears the stored Koha token and flips `AuthGate` back to the signed-out Welcome flow — no restart needed.

There's no equivalent "Login" button anywhere inside `RootShell` by design: `RootShell` only ever renders once `AuthGate` has confirmed a Koha session exists, so there's no reachable logged-out state from inside it to log in from.