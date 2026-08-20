# Deferred

Items intentionally left unresolved for now — revisit when asked.

## Colleague's laptop — known environment/setup (reference)

Reconstructed from diffing their pushed commit (`7af8391`,
`opac-search-filters-and-borrowing`) against what was on this machine at
the time. Not guessed — every value below is exactly what their commit
had. Worth checking against reality if you're ever debugging "works on my
machine, not theirs":

- **Runs on an Android emulator**, not a physical device or Flutter web/
  desktop — `ApiConstants.kohaBaseUrl` was `http://10.0.2.2:9090`, the
  special host-machine alias emulators use (`127.0.0.1` inside an
  emulator points at the emulator itself, not the host).
- **`useMockKohaBackend = false`** — pointed at a real local Koha, not
  the mock catalog. Since they never touched `koha_service_account.dart`,
  the same `apiuser`/`Api@1234` credential this app shipped with was
  apparently working against their instance too (now rotated — see the
  security-audit section below; they'll need the new value or their own
  local account to keep working).
- **Their Koha instance uses Koha's own stock demo/seed data**, not a
  real COMSATS-specific catalog — `defaultPickupLibraryId = 'CPL'`
  ("Centerville") is one of `koha-testing-docker`'s default demo
  libraries, the same ones seen on the throwaway dev instance used for
  live-testing this session, not a real COMSATS branch code. Likely
  means they're running the same `koha-testing-docker` setup locally,
  independently from this machine's.
- **`flutter_native_splash` pinned to `^2.4.7`**, one patch behind what
  this machine had (`^2.4.8`) — never confirmed why (a resolver conflict
  on their Flutter/Dart SDK version is the likely reason), but their
  version was kept on merge rather than overwritten, on the theory it
  reflects a real constraint on their machine rather than an arbitrary
  choice.
- **Different code formatter/IDE settings** — their diffs included
  widespread indentation-only changes unrelated to any functional edit
  (visible throughout their `opac.dart`/`biblio_service.dart` diffs),
  consistent with a different default Dart formatter (Android
  Studio/IntelliJ's built-in one uses different continuation-indent
  defaults than `dart format`'s CLI defaults). Not a bug, just something
  to expect if diffing against their commits again — most of the noise
  in any future diff will likely be this, not real changes.

## Silent Watch (availability alerts, no hold) — 2026-08-18

New `lib/services/watchlist_service.dart` — local-only (`SharedPreferences`,
same `ChangeNotifier` singleton shape as `BookBagService`), separate from a
real Koha hold entirely. Bell toggle on the book detail sheet, shown only
while `Availability.status == checkedOut` (watching an already-available
or no-items title is meaningless). Checked opportunistically in
`MyBooksScreen._load()` via `WatchlistService.checkForAvailabilityChanges()`
— same rebuild-on-screen-load pattern as due-date reminders, not true
background polling (no backend to run one on). Fires a local notification
via a new `NotificationService.notifyBookAvailable()` on a false→true
transition only, using a negative id-space (`-biblioId`) so it can never
collide with due-date reminders' `checkoutId`-keyed notifications. Entries
aren't auto-removed after notifying — they flip to an "Available now!"
badge in the new Watching section of My Books and stay until the student
removes them, so nothing disappears silently.

No new Koha API surface — reuses `fetchAvailability()`, already confirmed
real and public (no auth) earlier this session.

## Architectural fix for security finding #2 (2026-08-18) — built, NOT deployed or tested

Built a Cloudflare Worker (`/worker`, see `worker/README.md`) that brokers
all circulation calls (checkouts/holds/account/checkout-limit/login
validation) instead of the app calling Koha directly with the embedded
staff credential. It verifies the caller's real Firebase ID token
(signature-checked against Google's public JWKS, not just decoded),
resolves that verified user's OWN Koha patron_id server-side (queries
`student_requests` where `firebaseUid` matches, using a GCP service
account — this is where the actual patron/Firebase link lives; confirmed
by reading admin-dashboard.html's `approveStudentRequest` directly,
**not** the `users/{uid}.kohaBorrowerNumber` an older, no-longer-used
`functions/index.js` draft assumed), and only then calls Koha with that
ID — never anything the client sends. Renewal/cancel additionally verify
the target checkout/hold actually belongs to the resolved patron before
forwarding the action.

`CirculationService` and `KohaAuthService` were rewritten to call this
Worker (via `ApiConstants.circulationProxyBaseUrl`, currently empty —
nothing points at it until it's deployed) instead of Koha directly,
authenticated with the student's Firebase ID token
(`FirebaseAuth.currentUser.getIdToken()`) instead of the embedded
`KohaServiceAccount`. `koha_service_account.dart`'s credential is no
longer used for circulation or login validation at all after this.

**What's still exposed, deliberately, for now**: `BiblioService` (catalog
search) still calls Koha directly with the embedded credential — scoped
out on purpose, since catalog data is public-equivalent to what the real
OPAC website already shows anyone, not the privacy-sensitive surface this
fix targets. The rotated Koha password from the earlier audit is still
live in the app for that one purpose.

**What could NOT be verified from here — this is real, not hypothetical**:
- No Node.js/npm available in this environment at all, so the Worker's
  JavaScript was never run, not even syntax-checked with a real engine —
  only reviewed by eye. The `jose` library's API surface (`jwtVerify`,
  `createRemoteJWKSet`, `SignJWT`, `importPKCS8`) was used from general
  knowledge of a well-established library, not verified against its
  actual installed source the way every Flutter package this session was
  — unlike everything else built this session, this is a real gap in
  rigor, not a minor caveat.
- Never deployed — no Cloudflare account access, no real Firebase
  service-account key, no real production Koha URL to point it at.
  `ApiConstants.circulationProxyBaseUrl` is empty; until it's filled in
  with a real deployed Worker URL, `CirculationService`/`KohaAuthService`
  will fail every call (there's nothing at `''` + `/login` etc.).
- The Firestore `student_requests` query assumes firestore.rules permits
  a service-account read (service accounts bypass rules entirely by
  design, so this should be fine, but it's still unverified against the
  real deployed rules — same open item as security finding #4).

**Next steps, in order**: deploy per `worker/README.md`, point
`circulationProxyBaseUrl` at the real Worker URL, then test the full
loop end-to-end (login → fetch checkouts → place a hold → cancel it)
against a real Koha instance before trusting this with real student data.

## Security audit 2026-08-18 — secrets rotated, HTTPS guard added, action still needed

Ran a security review of the codebase. Confirmed via GitHub's API that
`kamal-hassan-1/junaid-zaidi-library-app` is a **public** repo. Findings,
most severe first:

1. **[ROTATED, but old values still need server-side revocation]**
   `CryptoConstants.passwordEncryptionSharedSecret` (decrypts every
   pending student's real password) and `KohaServiceAccount.
   validatorPassword` (staff-level Koha account the app uses directly)
   were both hardcoded in this public repo — readable by anyone, forever,
   even now that the values have changed (git history keeps the old ones).
   New values generated and wired into `crypto_constants.dart`,
   `admin-dashboard.html`'s `PENDING_PASSWORD_SECRET`, and
   `koha_service_account.dart`. **This alone does nothing** — the OLD
   Koha `apiuser` password ('Api@1234') is still valid on any real Koha
   instance until someone changes it there directly, and the old AES
   secret can still decrypt any Firestore document that was encrypted
   with it before this rotation. Someone needs to: (a) change `apiuser`'s
   actual password on the real/production Koha, (b) confirm no pending
   `student_requests`/`password_change_requests` documents were encrypted
   with the old AES secret before this point (if any are, they'll fail
   to decrypt in admin-dashboard.html now — that's expected, not a bug).
2. **[Architectural, not fixed]** The Koha service account has no
   per-patron access boundary server-side — `CirculationService`'s own
   docs say patron ownership is "enforced client-side." Anyone with the
   credential (see #1) can query/act on any patron's data directly,
   bypassing the app entirely. Rotating the leaked password is a
   mitigation, not a fix — the real fix is either tighter Koha-side
   permissions on this account or a real backend brokering these calls,
   both bigger than a code change.
3. **[Fixed]** `ApiConstants.kohaBaseUrl` now runs through
   `_requireSafeUrl()`, which throws immediately (in every build mode,
   not just debug — this isn't an `assert`) if it's ever set to a plain
   `http://` URL pointing at a non-local host. Koha's Basic-Auth-resent-
   on-every-request scheme means HTTP on a shared network (campus WiFi)
   would otherwise leak real credentials in cleartext. `kohaBaseUrl`/
   `kohaAuthValidationEndpoint` changed from `static const` to `static
   final` to allow this runtime check — confirmed via `flutter analyze`
   that nothing downstream depended on them being compile-time constants.
4. **[Needs the real Firestore rules to audit]** `student_requests`
   documents store CNIC/phone/full name in plaintext. Whether that's
   actually exploitable depends entirely on Firestore security rules,
   which aren't in this repo (no `firestore.rules` file) — can't audit
   from here. Asked the user to paste the real deployed rules.

**Checked and found clean** (verified, not assumed): the `kDebugMode`-gated
dev login bypass in `koha_auth_service.dart` (compiler-stripped from
release builds); `admin-dashboard.html`'s card rendering (every
user-controlled field goes through a real `escapeHtml()` before
`innerHTML`, so the stored-XSS angle checked for isn't actually present);
`functions/` folder's git history (only a `.env.example` template was ever
committed, real `.env` never was, `google-services.json`'s content is
Firebase's normal non-secret client config).

## New features added 2026-08-18: fines/balance, checkout limit, hold queue position, share book bag

Also fixed a real bug this round: `CirculationService.placeHold()` was
omitting `pickup_library_id` when the caller didn't pass one — confirmed via
the colleague's branch comparison that Koha 400s without it. Added
`ApiConstants.defaultPickupLibraryId = 'CPL'` and wired it into the fallback
(affects both OPAC's single hold button and the new Book Bag bulk-hold).

- **Fines & account balance** (`lib/models/patron_account.dart`,
  `CirculationService.fetchAccount()`) — `GET /api/v1/patrons/{id}/account`.
  Live-verified by posting a real test debit
  (`POST /api/v1/patrons/{id}/account/debits`) and inspecting the actual
  response shape, not just docs: `{balance, outstanding_debits: {lines,
  total}, outstanding_credits: {...}}`, each line carrying
  `account_line_id`/`amount`/`amount_outstanding`/`description`/
  `debit_type`/`date`. Shown as a summary card above Checkouts in My Books;
  fetch failures are silent (checkouts/holds still load fine without it).
  Currency is displayed as "Rs." — an assumption based on this being a
  Pakistani university, **not** something the API told us (Koha's response
  has no currency field at all) — worth confirming against the real
  deployed instance's configured currency.
- **Checkout limit by patron category** (`CirculationService.
  fetchCheckoutLimit()`) — `GET /api/v1/circulation_rules?rules=
  maxissueqty&patron_category_id=X`. Confirmed live that this endpoint is
  real and does proper rule-specificity resolution (a category with no
  dedicated rule correctly falls back to the library's wildcard default
  instead of erroring). **What could NOT be confirmed**: the dev instance
  used for testing only has Koha's single default `maxissueqty` rule in its
  seed data — no per-category rows exist to inspect, so the actual
  undergrad-vs-grad-vs-PhD differentiation the user described couldn't be
  observed directly, only that the query mechanism correctly accepts and
  resolves a `patron_category_id` filter. Shown in My Books as "X of Y
  books borrowed"; `null` (no rule found) hides that part of the card
  rather than showing a wrong number.
- **Hold queue position** (`lib/models/hold.dart`) — `priority` is a real
  field, confirmed by placing an actual test hold and inspecting the
  response directly (previously listed as unconfirmed in this file).
  `Hold.statusLabel` now shows "Queue position #N" when waiting for a
  turn. Also confirmed while at it: `status` is genuinely `null` until a
  hold is filled (not `'W'` as a placeholder before then, as previously
  guessed) — no code change needed there, the existing `isWaiting` check
  was already correct by coincidence.
- **Share Book Bag as a list** (`book_bag_screen.dart`, new dependency
  `share_plus: 13.3.0`) — hands the bag's contents to the OS share sheet
  as plain text (numbered title/author list). Purely local formatting, no
  Koha call, no new permissions needed for text-only sharing on either
  platform.

**Not built yet — offline My Books cache is proposed, awaiting approval**
before implementation (user asked to hear the design first). Plan: cache
the last successfully fetched checkouts/holds/account to `SharedPreferences`
(same pattern as Book Bag) every time `_load()` succeeds; on a failed live
fetch, show the cached data instead of the error screen, labeled with a
"last synced" timestamp. Actions (renew/cancel/place hold) still require a
live connection — no offline action queue, since queuing something like a
renewal while offline risks double-submitting once back online, a
data-integrity problem deliberately out of scope unless asked for
specifically.

## New features added 2026-08-17: advanced search, search history; Lists debunked

Local Koha's custom `apiuser` service account (used all session) no longer
authenticates — 403 "Invalid password" on every endpoint, including ones
proven working earlier the same day. The container itself is fine (`docker
ps` shows 9h uptime) but a fresh patron record (`date_enrolled: 2026-08-17`,
today) shows the DB was reseeded at some point without `apiuser` surviving —
likely a `ktd` restart between sessions. Worked around it for this round's
live verification only by using the stock `koha-testing-docker` superlibrarian
(`koha`/`koha`, from `bin/koha-shell` docs) directly, **not** wired into the
app — `koha_service_account.dart` still points at the now-broken `apiuser`
and needs that account recreated before the app itself can hit this Koha
instance again.

- **Public/curated Lists — investigated, NOT built.** Last round's pitch
  ("Browse Collections screen pulling in the real site's named lists") does
  not survive contact with the actual API. Fetched the live OpenAPI spec
  (`GET /api/v1/`) and confirmed: the *only* lists-related path in the
  entire REST API is `GET /public/lists`, and its schema
  (`definitions.list_yaml`) has just `list_id`, `name`, `owner_id`, `public`,
  `creation_date`, `updated_on_date` — no `biblio_ids`, no `contents`, no
  item count, nothing that says what's *in* a list. Confirmed live too:
  `GET /api/v1/public/lists` returns `200 []` cleanly (real endpoint, just
  no lists on this fresh instance). There is no REST path to fetch a list's
  contents — the only way to see what's inside one is Koha's own
  server-rendered `opac-shelves.pl` HTML page, which would mean scraping
  HTML instead of calling an API, a different (and much more fragile) kind
  of integration than everything else in this app. Not building this.
- **Advanced search** (`lib/screens/advanced_search_screen.dart`,
  `BiblioSource.advancedSearch()` in both `biblio_service.dart` and
  `mock_biblio_service.dart`) — ANDs title/author/isbn/issn/publisher/
  series_title/publication_year/item_type together, all via the same JSON
  `-like` condition mechanism `search()` already uses (see the "RESOLVED"
  section below), just with more than one field at once. **Live-verified
  before writing the app code**, not assumed: pulled the real `biblio`
  field list straight off a live record (`GET /api/v1/biblios?_per_page=1`)
  to get the exact real column names, then ran real AND-combination
  requests — `{"item_type":"BK","author":{"-like":"%Kernighan%"}}` and
  `{"title":{"-like":"%C programming%"},"author":{"-like":"%Kernighan%"}}`
  both correctly returned only "The C programming language". Also confirmed
  `publication_year`/`publisher` are real, accepted, queryable columns
  (200 responses, just empty results — the seed data's values for those
  two happen to be null on this instance, a data-quality gap, not a syntax
  problem). `OpacScreen` now has an "Advanced Search" entry point that
  pushes the new screen and, on a result, replaces whatever the plain
  search bar/filters had (the two aren't composable in the current UI —
  running an advanced search clears the normal query/filters and vice
  versa).
- **Search history** (`lib/services/search_history_service.dart`) —
  local-only, `SharedPreferences`, same `ChangeNotifier` singleton shape as
  `BookBagService`. The real OPAC website tracks search history
  server-side per logged-in Koha session, which this app doesn't have (it
  never establishes a Koha session — see the Basic Auth findings below), so
  this is a local approximation, not a synced equivalent. Shown as
  removable chips under the search bar whenever it's empty; tapping one
  re-runs that search, feeding back into the exact same `_runSearch` path
  a manual search does.

## New feature added 2026-08-17: due-date reminders

`lib/services/notification_service.dart` (new deps: `flutter_local_notifications`,
`timezone`, `flutter_timezone`) — schedules a local notification at 9am the day
before each open checkout's `due_date`. Zero new Koha API surface: it only reads
`Checkout.dueDate`/`checkinDate`, both already confirmed real fields (see
"RESOLVED 2026-08-17" below). Wired into `my_books_screen.dart`'s `_load()` and
`_renew()` — every time either runs, ALL pending reminders are cancelled
(`_plugin.cancelAll()`) and rescheduled fresh from the current checkout list.
This is deliberately a full rebuild, not a diff: it means renewals, returns, and
new checkouts are all self-correcting for free (no bookkeeping of what a stale
reminder was "for"), at the cost of reminders only ever reflecting what was
checked out as of the last time My Books was opened.

Design choices worth knowing if this needs revisiting:
- **Uses `AndroidScheduleMode.inexactAllowWhileIdle`, not exact.** Exact
  scheduling on Android 12+ needs the user to separately grant
  `SCHEDULE_EXACT_ALARM` in system settings — too much friction for a
  "day before" reminder that doesn't need to-the-minute precision. Only
  `POST_NOTIFICATIONS` is requested (Android 13+ runtime prompt).
- **No reboot persistence.** A device restart clears pending Android alarms;
  nothing here reschedules them until My Books is opened again. Adding
  `RECEIVE_BOOT_COMPLETED` + a rescheduling receiver was judged not worth the
  extra manifest surface for what this feature needs.
- **Permission is requested contextually**, not at app launch — only when
  `scheduleDueDateReminders` actually has something to schedule (i.e. the
  first time a signed-in student with an open checkout opens My Books), so
  guests and browsing-only users never see the OS permission prompt.
- **Notification id = `checkout_id`** (Koha's own integer, already used
  elsewhere in the app) — no separate id-tracking needed.
- **Not tested end-to-end from here** — no physical device/emulator with a
  real due date a day out was available to watch a reminder actually fire.
  `flutter analyze` is clean and the plugin API calls were verified against
  the installed `flutter_local_notifications 22.3.0` source directly
  (`initialize`, `zonedSchedule`, `requestNotificationsPermission`,
  `AndroidScheduleMode.inexactAllowWhileIdle` all confirmed to exist with
  the signatures used), but actually seeing a scheduled OS notification
  fire needs real time to pass on a real device — worth checking once one's
  available.

## New features added 2026-08-17: availability, book bag, barcode scanner, real covers

- **Availability** (`lib/models/availability.dart`) — real path confirmed
  live: `GET /api/v1/public/biblios/{id}/items` is genuinely
  unauthenticated (no service-account credentials sent), computed from
  real fields (`checked_out_date`, `lost_status`, `withdrawn`,
  `damaged_status`, `not_for_loan_status`). `MockBiblioService`'s version
  is a deterministic fake (cycles through available/checked-out/no-items
  by `biblioId % 4`) purely so the UI has all three states to render —
  not meant to reflect anything real.
- **Book bag** (`lib/services/book_bag_service.dart`,
  `lib/screens/book_bag_screen.dart`) — local-only, `SharedPreferences`,
  never touches Koha except when placing bulk holds. Mirrors the real
  OPAC website's own cart, which is also browser-local.
- **Barcode scanner** (`lib/screens/barcode_scanner_screen.dart`, new
  dependency `mobile_scanner: 7.4.0`) — looks up the scanned code via
  `search(code, searchField: 'nb')`, same ISBN search path already
  verified against real Koha. Added `CAMERA` permission
  (`android/app/.../AndroidManifest.xml`) and `NSCameraUsageDescription`
  (`ios/Runner/Info.plist`). **Not tested with an actual camera/physical
  book from here** — no camera hardware available in this environment;
  the ISBN-lookup logic is verified, the scan-detection itself isn't.
- **Real cover images** (`_BookCoverImage` in `opac.dart`) — OpenLibrary
  Covers API (`covers.openlibrary.org`, free, no key), `?default=false`
  so a missing cover 404s cleanly instead of showing a generic
  placeholder image, with `errorBuilder` falling back to the existing
  gradient+icon look. **Not visually verified from here** — this
  session's network couldn't reach `covers.openlibrary.org` at all
  (DNS resolution itself was timing out) when this was built, so the
  fallback path is what's actually been exercised, not the real-image
  path. Worth a real check once network/an actual device is available.

## RESOLVED 2026-08-17 — real local Koha stood up, search + circulation fully verified

Set up a real Koha instance locally via `koha-testing-docker` (Docker Desktop +
WSL2 Ubuntu — see "Local Koha setup notes" below for how to reproduce/restart
it). This is a genuine Koha 26 install with real seeded sample data, reachable
at `http://localhost:8080` (OPAC) / `http://localhost:8081` (staff + REST
API), superlibrarian login `koha`/`koha`. Tested every endpoint this app
uses directly against it — not curl guesses, the actual Dart code paths.

**Biblio model — fully confirmed correct.** Every field `Biblio.fromJson`
parses (`biblio_id`, `title`, `author`, `isbn`, `issn`, `publisher`,
`publication_year`, `edition_statement`, `pages`, `item_type`, `abstract`,
`notes`, `serial`, `opac_suppressed`, etc.) matches the real response
exactly. **`subjects`/`home_library_id` do not exist on the real biblio
response at all** — confirmed, not just suspected. `home_library_id` is an
*item*-level field (see `GET /api/v1/items/{id}`), not filterable on
biblios. The campus filter and subject search field in `opac.dart`
currently have no real backend to work against; either drop them from the
real-API path or find the actual right mechanism (item-level join?) later.

**`BiblioService.search()` was fundamentally wrong — now fixed.** Koha's
`/api/v1/biblios` does **not** accept simple named query params
(`title=`, `itemtype=`, `home_library_id=`, `subject=` — all 400 or
"Malformed query string"). The only filter mechanism is a single `q` param
holding **JSON-encoded SQL::Abstract-style conditions**: a plain hash ANDs
its keys (`{"item_type":"BK"}`), `{"field":{"-like":"%x%"}}` does a
substring match, and a `-or` key with an array ORs those entries while
still ANDing with sibling keys — e.g.
`{"item_type":"BK","-or":[{"title":{"-like":"%x%"}},{"author":...}]}`.
Rewrote `biblio_service.dart` to build this correctly; verified with the
actual Dart query-building code (not just curl) against real Koha —
keyword, title-only, item-type-only, and combined type+keyword searches
all returned correct, sensible result sets. `su`/subject search field was
dropped from the real path (no such field exists); `campus` currently has
no effect against real Koha (see above).

**Circulation auth model was wrong — now fixed, this was the big one.**
Confirmed live: a plain "Student"-category patron, authenticating with
their *own* Basic Auth credentials, gets **403 Authorization failure**
on `/api/v1/checkouts`, `/api/v1/holds` — even for their own
`patron_id`. Koha requires staff-level `circulate`/`reserveforothers`
permissions by default; a default self-registered/created student patron
doesn't have them. This directly answers the open question the PDF itself
raised ("student sessions should not use the staff token... confirm
whether Koha separates this") — it doesn't, not by default. Rewrote
`circulation_service.dart` to use the shared `KohaServiceAccount` (same
pattern as `BiblioService`) instead of the student's own stored
credentials. The safety property this needs — a student must never
see/act on another patron's data — was **already** correctly enforced
client-side (`_requirePatronId()` always sources `patron_id` from secure
storage, never a caller argument) and needed no change; only the
*authentication mechanism* reaching the API was wrong. Removed
`KohaSessionExpiredException` handling from `my_books_screen.dart`/
`opac.dart`'s circulation call sites since that no longer applies —
`KohaApiClient`/`koha_api_client.dart` is now unused dead code (kept, not
deleted, in case a genuine student-self-service use case shows up later
that *does* work with student-level permissions — e.g. viewing/editing
their own profile might, unlike circulate operations; untested).

Also confirmed live: `Checkout`/`Hold` field shapes exactly match what was
already built from the user's PDF screenshots (both models needed zero
further field changes) — `patron_id` field, `renewals_count` are extra
fields present on the real response, not currently modeled, harmless to
add later. `pickup_library_id` must be a real registered library code
(`GET /api/v1/libraries`) — a bib with no holdable items, or an item not
loanable to that pickup point, returns `"The supplied pickup location is
not valid"`, which is a real per-item/per-library-policy condition, not a
bad code.

**`admin-dashboard.html`'s open password-endpoint question — resolved.**
That file's `updateKohaPatronPassword` tries 4 candidate endpoints because
the real one was never confirmed. Tested all 4 directly: **the real one is
`POST /api/v1/patrons/{patron_id}/password`** (200) — the other three
(`PATCH /patrons/{id}`, `PATCH .../password`, `PUT .../password`) all 404.
Verified the password it sets actually authenticates afterward. This can
be simplified from the 4-candidate probe back to a single direct call —
not done here since it's a separate file/workflow, but the answer is in
hand whenever that's picked up.

### Local Koha setup notes (for restarting/reproducing)

- `koha-testing-docker` cloned to `C:\Users\awais\koha-testing-docker`,
  Koha source (shallow clone, required as `SYNC_REPO`) to
  `C:\Users\awais\koha`. Both are **outside** the app repo, untracked by
  git here, not part of anything pushed.
- **Real root cause of repeated earlier setup failures: CRLF line
  endings**, not Docker/WSL flakiness (that was a red herring chased for a
  while before this was found). Windows git checkouts convert LF→CRLF by
  default; any shell script executed inside the Linux container
  (`bin/ktd`, `.env`, and critically `debian/scripts/*` in the Koha source
  tree, which the container copies and executes directly) breaks with
  `bad interpreter`/`cannot execute: required file not found` if not
  fixed. Set `git config core.autocrlf input` on both repos and stripped
  `\r` from every text file — for the Koha source specifically, only
  `debian/` needed fixing (783K, 143 files — not the whole 148MB tree,
  which is too slow to sed file-by-file on Windows).
- Run via WSL2 Ubuntu (`wsl.exe -d Ubuntu -e bash -lc '...'`), not
  git-bash directly on Windows — Docker Desktop's Windows CLI and
  bind-mount path handling are unreliable for this from git-bash.
  Environment needed: `KTD_HOME=/mnt/c/Users/awais/koha-testing-docker`,
  `SYNC_REPO=/mnt/c/Users/awais/koha`, `PATH=$PATH:$KTD_HOME/bin`,
  `LOCAL_USER_ID=$(id -u)`.
- Startup sequence: `ktd --search-engine zebra pull` (~2.5GB, several
  minutes), `ktd --search-engine zebra up -d`, then
  `ktd --wait-ready 600` (Koha's first-run DB install/seed takes ~4-5
  minutes after containers start — don't assume ready just because
  containers are "Up").
- Ports: OPAC `8080`, staff interface + REST API `8081`. Superlibrarian
  login `koha`/`koha` (from `.env`'s `KOHA_USER`/`KOHA_PASS` defaults —
  this is also the real Koha patron `userid`, confirmed by querying the
  `borrowers` table directly).
- To stop: `docker compose --project-directory ~/koha-testing-docker -p
  kohadev down` (or `ktd down` with the same env vars set). Containers
  are on this machine only — zero effect on anyone else's setup.

### New blocker found: login-validation endpoint 500s on this instance

`POST /api/v1/auth/password/validation` — the endpoint the app's entire
login flow (`KohaAuthService.login`) depends on — throws a genuine
**server-side 500** on this local instance: `{"errors":[{"message":"Expected
string - got null.","path":"/body/cardnumber"}]}`, regardless of whether
the request sends `userid` or `identifier` (both are valid per the
endpoint's own OpenAPI schema, which does NOT list `cardnumber` as a
valid input at all — sending it explicitly gets a different error,
"Properties not allowed: cardnumber"). This isn't a request-format
problem; it looks like a real bug in Koha's internal implementation of
this endpoint on whatever snapshot `koha-testing-docker`'s default
`KOHA_IMAGE=main` pulled (Koha's bleeding-edge dev branch, not a stable
release). Search and circulation both work fine — this is specific to
login validation.

**Not yet tried:** pinning `KOHA_IMAGE` to a stable release tag (e.g. a
specific `24.11`/`25.05`-style tag) instead of `main` and re-pulling, to
see if a stable version doesn't have this bug. That's another
multi-GB/several-minute pull — hasn't been done, would need your go-ahead
given today's already-long setup process.

## OPAC item-type filter codes are placeholders

`_typeFilters` in [lib/screens/opac.dart](lib/screens/opac.dart) and the mock
entries in [lib/services/mock_biblio_service.dart](lib/services/mock_biblio_service.dart)
use `EBOOK` and `THESIS` as itemtype codes. Koha's default itemtype table
only ships `BK`, `CF`, `CR`, `MP`, `MU`, `MX`, `RE`, `VM` — `EBOOK`/`THESIS`
are guesses, not confirmed against a real Koha instance.

**To fix:** once real Koha access is available, check
**Administration → Item types** (or `GET /api/v1/item-types`) for the actual
codes in use, then update `_typeFilters` to match.

**Alternative worth considering:** instead of hardcoding the list, fetch it
from Koha's `/api/v1/item-types` endpoint at runtime so the dropdown always
reflects whatever's actually configured — removes the guesswork entirely.

Also unresolved: [lib/services/biblio_service.dart](lib/services/biblio_service.dart)
sends the type filter as `itemtype=` query param on `GET /api/v1/biblios` —
this param name is a guess and needs confirming against the real API.

## Borrowing (checkouts/holds) runs against a local stub, not real Koha

[lib/services/circulation_service.dart](lib/services/circulation_service.dart)
talks to `ApiConstants.kohaBaseUrl` via the real `KohaApiClient` (genuine
HTTP + JSON parsing — not an in-Dart fake like `MockBiblioService`), but
right now that URL is served by
[tool/koha_stub_server.dart](tool/koha_stub_server.dart), a hand-written
local stand-in (`dart run tool/koha_stub_server.dart`), because no real
Koha instance was reachable when this was built. Only the dev bypass
account (`testuser` / `test1234`, patron_id `0000`) works against it.

**UPDATE 2026-08-17 — real field shapes now confirmed and applied.** The
user shared real Postman screenshots (checkouts/renewal/holds tested
against a live Koha at `127.0.0.1:9090` — a *different* environment than
this one, not reachable from here — see the auth section below).
`Checkout`/`Hold`/the stub were rewritten to match:

- **Checkouts are per-*item*, not per-title** — confirmed real fields:
  `checkout_id`, `item_id`, `checkout_date`, `due_date`, `library_id`,
  `auto_renew`, `last_renewed_date`, `checkin_date`, `checkin_library_id`,
  `booking_id`, `issuer_id`. **No `biblio_id`, `title`, `author`,
  `renewable`, or `renewals_remaining`** — those were the old guesses,
  now removed from `Checkout`. Getting a display title requires
  `item_id` → `GET /api/v1/items/{id}` (returns `biblio_id`) → the
  biblio itself — `CirculationService` now does this as a follow-up
  lookup per checkout, same pattern the PDF's own reference table
  describes ("Same lookup used by Search").
- Since there's no `renewable` flag, the Renew button in
  `my_books_screen.dart` is now always enabled — a rejected renewal
  surfaces as a normal error instead of being predicted client-side.
- **Holds carry `biblio_id` directly** — confirmed real fields:
  `hold_id`, `biblio_id`, `item_id`, `item_level`, `hold_date`,
  `expiration_date`, `cancellation_date`, `cancellation_reason`. **Still
  unconfirmed:** `status` and `pickup_library_id` — the screenshot this
  was built from was cut off before showing whether/how they appear on a
  real `GET` response. `Hold.status`/`statusLabel` in
  `lib/models/hold.dart` are marked accordingly; verify before trusting
  the "Ready for pickup" label against real data.
- `title`/`author` on both models are populated by
  `CirculationService`'s enrichment step, not parsed from the raw
  response — they're not part of Koha's real shape at all.

**Still open:** the stub (and therefore this whole flow) has never been
exercised against a Koha instance reachable from *this* environment —
only against the `127.0.0.1:9090` shown in the user's screenshots, which
is a separate machine/session. Re-verify once real access exists here.

## BLOCKER: real Koha REST API rejects Basic Auth entirely — login is broken as designed

Investigated directly against the real production server
(`lib.comsats.edu.pk:82`), 2026-08-16/17. Findings, most important first:

1. **`/api/v1/auth/password/validation` — the endpoint the app's entire
   login flow depends on (`KohaAuthService.login`) — returns
   `{"error":"Basic authentication disabled"}` for a real student login
   attempt**, using the exact same request shape the app sends (validator
   account's Basic Auth header + student userid/password in the JSON
   body). This is Koha's `RESTBasicAuth` system preference, off
   server-wide. It rejects every account, not just this one — it's not a
   permissions or wrong-password problem.
2. The code comments in `koha_auth_service.dart`/`api_constants.dart`
   say this was "confirmed via Postman" to work with Basic Auth. Either
   `RESTBasicAuth` was switched off on the server since then, or that
   earlier testing was against a different (non-production) Koha
   instance. Can't tell which from here.
3. **This blocks the whole Koha side of the app against the real server
   as currently built — not just search, not just circulation, login
   itself.** `KohaApiClient`'s entire design (Basic-Auth-per-request) is
   built on an assumption that's currently false in production.
4. `/api/v1/auth` (session-cookie login) doesn't exist on this Koha
   version — 404.
5. A direct OPAC web-form login attempt (`opac-user.pl`, tried both the
   full COMSATS email and the email's local part as `userid`) also came
   back "incorrect username or password" for the one real student account
   tested — separate from the Basic Auth issue, this could mean that
   particular account isn't provisioned in Koha, or the password isn't
   synced there, or something else. Not conclusively diagnosed either
   way; only one account was tried, deliberately, since guessing further
   credentials against a live production login isn't appropriate.

**Two real ways forward, both needing your Koha admin, not app code:**
- Ask whoever administers the Koha server to re-enable `RESTBasicAuth` —
  if that's what changed, this unblocks everything immediately with zero
  app changes.
- Or move the app to OAuth2 client-credentials (Koha's other REST auth
  method) — needs an API key (client_id/secret) generated for a service
  account under Koha's Administration, then `KohaApiClient` gets reworked
  to fetch/attach a bearer token via `/api/v1/oauth/token` instead of
  Basic Auth.

**Decided 2026-08-17:** paused for now — continuing to build app-side
(filters, UI) against the mock/stub until the server-side auth question
is resolved. Revisit this before assuming *any* real-Koha wiring works,
including the parts already written under the old Basic-Auth assumption
(`biblio_service.dart`, `circulation_service.dart`, `koha_api_client.dart`,
`koha_auth_service.dart`).

**UPDATE 2026-08-17 (correction):** the `Authorization: Bearer <token>`
shown in "Opac Endpoint.pdf"'s screenshots was a mistake in how that
Postman testing was set up — confirmed by the user. The real, intended
mechanism is Basic Auth, same as the rest of this app already assumes.
That testing was run against a Koha instance at `http://127.0.0.1:9090` —
a different environment than this one (nothing real is reachable at that
address from here; confirmed it's this app's own local stub server
answering instead when checked) — where Basic Auth genuinely works.

**This does NOT resolve the production-server blocker above.** Both are
true at once, because they're different servers with different configs:
- `127.0.0.1:9090` (wherever that is): Basic Auth enabled, confirmed
  working (the PDF's testing).
- `lib.comsats.edu.pk:82` (real production): Basic Auth explicitly
  disabled, confirmed by this session's own direct test
  (`{"error":"Basic authentication disabled"}` from
  `/api/v1/auth/password/validation`, the app's actual login endpoint).

**Decided 2026-08-17:** keep Basic Auth in the code as-is — no auth
rework needed, `KohaApiClient`'s existing design was correct all along.
What's still needed before login/search/circulation can work against the
*real* production server specifically: someone with Koha admin access
needs to re-enable the `RESTBasicAuth` system preference there. This is
a server-config task, not an app change.

**POLICY 2026-08-17:** `lib.comsats.edu.pk:82` is production and is
**hands-off during testing** — the user confirmed it stays untouched
until they explicitly transfer/go live later. No further direct
requests against it (not even read-only checks) without asking first.
The app is meant to connect straight to whatever Koha backend the real
website itself talks to (REST API, not the website's HTML/CGI layer) —
confirms the existing `BiblioService`/`CirculationService` design is
architecturally correct, this was never in question. What's still
missing is a reachable **test/staging** Koha instance to actually build
and verify against instead of production — not yet provided; the mock/
stub remains the only thing to develop against until one is.

## Real search-index and item-type facets confirmed from the live OPAC website

Learned by fetching `lib.comsats.edu.pk:82/cgi-bin/koha/opac-search.pl`
directly (the classic Perl-CGI OPAC UI, not the REST API — Apache/2.4.41,
CGISESSID session, every filter/sort/page is a plain query-string GET,
no client-side search logic at all):

- Search index (`idx=`): empty/`kw` = keyword, `ti` = title, `au` =
  author, `su` = subject, `nb` = ISBN, `ns` = ISSN, `se` = series,
  `callnum` = call number.
- Item type facet (`limit=itype:...`) — **real confirmed codes for this
  library: `BK` (Books), `EBK` (E-Books — not `EBOOK`, that guess was
  wrong), `CF` (Computer Files/Software).** No `THESIS` (or equivalent)
  code appeared in the facets for a "database" search — either this
  library doesn't tag theses as a separate itemtype, or a different query
  would surface it. Some facet values for this specific multi-campus
  install are messy (raw barcodes and branch-prefixed codes like
  `LHR 14692` showing up as itemtype facet entries) — real catalog data
  isn't as clean as a hardcoded list assumes.
- Other facets available the same way: `limit=available` (availability),
  `limit=au:...` (author), `limit=ccode:...` (collection code),
  `limit=location:...` (shelving location), `limit=su-to:...` (subject).
  Multiple `limit=` clauses AND together.
- Sort (`sort_by=`) and pagination (`offset=`/`count=`) are also just
  query params — `relevance`, `title_dsc`, `author_az`,
  `call_number_asc`, `pubdate_dsc`, `acqdate_dsc`, `popularity_dsc`, etc.

**Update `_typeFilters` in `opac.dart` and `MockBiblioService`'s itemType
values to `BK`/`EBK`/`CF`** (dropping the `EBOOK`/`THESIS` guesses) — this
is now a *confirmed* real value, not a placeholder, independent of the
auth blocker above.

**DONE 2026-08-17:** OPAC now has three working filters against the
mock/stub, all mirroring the real site's confirmed parameters — search
field (`idx=`: Keyword/Title/Author/Subject/ISBN/ISSN), item type
(`BK`/`EBK`/`CF`/`THESIS`), and campus (`homebranch:`:
isb/lhr/atd/atk/swl/veh/wah, all seven confirmed real from the live
site's "Home libraries" facet). `Biblio` gained `subjects` and
`homeLibraryId` fields to back this. **Still a guess:** the REST API
query param names `BiblioService` sends for these
(`home_library_id`/`subject`/`issn`, in `biblio_service.dart`) — the CGI
site's real param names (`homebranch`/`su`/`ns`) are confirmed, but
REST's likely-different attribute-name convention for the same filters
is not, same caveat as `itemtype` above. None of this has been exercised
against a real REST API response yet (blocked on the auth question).
