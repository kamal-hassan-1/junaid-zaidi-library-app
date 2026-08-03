# Authentication — how it actually works

This document was rewritten from scratch to match the current
implementation (the "Updated Authentication Workflow" build, phases
0-6). It previously described an earlier Koha-only login design that
had already been superseded in code without this file being updated —
if you're comparing against an old copy of this file or against
`Authentication_Complete_Build_Reference.docx` /
`Junaid_Zaidi_Library_Auth_Final_Reference.docx`, **this file describes
what's actually running**; those two describe earlier design points
along the way, not the current system.

## In one paragraph

A student fills in one registration form. Their password is RSA-OAEP
encrypted client-side and the whole thing is written to Firestore as a
`Pending` request — no Firebase account and no Koha patron exist yet. A
librarian reviews it in a web dashboard. On approval, a Cloud Function
decrypts the password, creates a real Firebase account, creates a Koha
patron with the same credentials, and links the two by storing the Koha
borrower number on the student's Firebase-keyed `users/{uid}` document.
From then on, logging in sends the same email + password to **both**
Firebase Auth and Koha's own login endpoint — both must succeed.
Changing a password later goes through the same admin-approval loop, so
Firebase and Koha never drift out of sync.

## Why no account exists before approval

Firestore Security Rules can't fully enforce "nobody logs in until a
human says so" if a real, working Firebase account already exists at
signup time — someone could sign in immediately, approval or not. The
fix here is to not create the account until approval happens. The
tradeoff: writing the *pending* request to Firestore still needs
`request.auth != null` to satisfy the rules, so registration signs in
**anonymously** first (a throwaway session, unrelated to the student's
real email/password, signed back out the instant the write succeeds).
See `FirestoreService.submitStudentRequest`.

## The password's journey

1. **Client (`lib/services/crypto_service.dart`)**: RSA-OAEP (SHA-256)
   encrypts the plaintext password using a public key embedded in
   `lib/config/crypto_constants.dart`. This class can only encrypt —
   there's no decrypt method anywhere in the Flutter app.
2. **Firestore**: the encrypted blob sits on the `student_requests`
   document as `encryptedPassword` while `status == 'Pending'`.
3. **Cloud Function (`functions/index.js`, `onStudentRequestApproved`)**:
   the only place in the entire system holding the RSA **private** key
   (`functions/.env`, never committed). Decrypts the password, creates
   the Firebase user with it, creates the Koha patron with it
   (`userid` = email, so one email+password pair works for both
   systems), then deletes `encryptedPassword` from the document.
4. **Password changes** later follow the identical pattern through
   `password_change_requests` / `onPasswordChangeApproved` — nothing
   ever stores a plaintext password anywhere, even transiently, outside
   Cloud Functions memory during that one decrypt-and-use step.

## Login

`lib/screens/auth/email_login_screen.dart` is the only real login
screen. It:
1. Calls `FirebaseAuthService.signInWithEmailAndPassword`. Since
   Firebase accounts are only ever created post-approval, a
   `user-not-found` error here doesn't necessarily mean "wrong
   password" — `describeSignInFailure` checks the student's
   `student_requests` history to tell "still pending" apart from
   "rejected" apart from "just wrong password".
2. Calls `KohaAuthService.login` with the same email + password.
3. If Koha rejects credentials Firebase just accepted, signs back out
   of Firebase immediately — the app is never left half-authenticated,
   with one system thinking the student is in and the other not.

Session restore on app boot (`AuthGate._checkSession`) applies the same
"both or neither" rule: it only trusts a persisted session if **both**
the Koha token (secure storage) and a live Firebase session are
present. If only one is found, both get cleared and the student sees
the login screen again rather than a half-valid session being silently
accepted.

## Koha API access — two different credentials, easy to mix up

- **Student login** (`api_constants.dart`'s `kohaAuthEndpoint`, i.e.
  `POST /api/v1/auth/password`): what the app calls directly, on behalf
  of one specific student, with their own credentials.
- **Staff/admin API** (`functions/.env`'s `KOHA_OAUTH_CLIENT_ID` /
  `KOHA_OAUTH_CLIENT_SECRET`, OAuth2 client-credentials grant): what the
  Cloud Function uses to create patrons and update passwords on anyone's
  behalf. This needs `borrowers` add/edit permission in Koha and must
  never be embedded in the Flutter app — it lives only in
  `functions/.env`, deployed as Cloud Function environment config.

`lib/services/koha_api_client.dart` exists as ready-to-use
infrastructure for attaching the Koha token to *other* future API calls
(catalog search, checkouts, holds, renewals, fines) — as of this
writing those features don't exist yet anywhere in this app; that
client is the plumbing for whichever gets built first.

## Admin dashboard (`admin-dashboard.html`)

Two sections, switched by tab: **Registrations** (`student_requests`)
and **Password Changes** (`password_change_requests`). Both show a red
"Automated processing failed" banner on any document with a
`processingError` field — written by the Cloud Functions whenever the
Koha side fails (wrong staff credentials, Koha unreachable, etc). An
admin approving a request always finishes instantly on the Firestore
side; if the automated account-creation/password-sync step then fails,
this banner is the only signal — without it, a student could sit
"Approved" but genuinely unable to log in with no visible reason why.

## Known gaps and things to verify against a real Koha instance

None of Phases 0-6 were tested against a live Koha server — there was
no staff API access available while building this. Before relying on
any of this in production:

- **`functions/index.js`'s patron-password-update endpoint**
  (`PUT /api/v1/patrons/{id}/password`) is an educated guess, flagged
  with a comment in the code. Confirm the actual path for your Koha
  version.
- **Patron category/branch codes** (`KOHA_PATRON_CATEGORY_CODE`,
  `KOHA_LIBRARY_BRANCHCODE`) are placeholders — set them to values that
  exist in your Koha instance.
- **Department and CNIC** have no first-class Koha patron field.
  `createKohaPatron` has a commented-out `extended_attributes` block —
  uncomment and adjust the `type` codes once you've defined matching
  Patron Attribute Types in Koha's admin interface, or drop the fields.
- **RSA keypair**: the one currently embedded in `crypto_constants.dart`
  / `functions/.env` was generated for development and has been visible
  in chat history — treat it as burned. Generate a fresh pair before
  any real student data flows through this.
- **Secrets in `.env`**: `functions/.env` is deploy-time environment
  config, not Secret Manager. Fine for a student project; migrate
  `RSA_PRIVATE_KEY` and the Koha OAuth secret to
  `firebase functions:secrets:set` + `defineSecret()` before this
  handles anything real.
- **No catalog/checkouts/holds/renewals/fines features exist yet.**
  `KohaApiClient` is ready for them; nothing calls it yet.
- **Password policy** (8+ chars, letters + digits) is a documented
  assumption made while building the registration and password-change
  screens, not a literal requirement from any source doc. Tighten it if
  COMSATS has an actual policy to follow.

## File map

| Concern | File(s) |
|---|---|
| Client-side encryption | `lib/services/crypto_service.dart`, `lib/config/crypto_constants.dart` |
| Registration | `lib/screens/auth/signup_form_screen.dart`, `lib/models/student_request.dart` |
| Firestore writes | `lib/services/firestore_service.dart` |
| Login (dual auth) | `lib/screens/auth/email_login_screen.dart` |
| Firebase auth | `lib/services/firebase_auth_service.dart` |
| Koha auth | `lib/services/koha_auth_service.dart` |
| Session gate | `lib/screens/auth/auth_gate.dart` |
| Koha API infra (future features) | `lib/services/koha_api_client.dart` |
| Password change request | `lib/screens/more/request_password_change_screen.dart`, `lib/models/password_change_request.dart` |
| Account creation + password sync automation | `functions/index.js` |
| Security rules | `firestore.rules` |
| Admin review UI | `admin-dashboard.html` |