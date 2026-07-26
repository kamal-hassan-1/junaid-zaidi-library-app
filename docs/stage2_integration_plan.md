# Stage 2 — Koha VM integration plan

How the Flutter client gets from mock repositories to a local Koha VM by way of a
local Juno backend. Planning only: no code, and nothing in the app changes as a
result of this document.

## What this plan is and is not based on

Read this section before trusting any row below.

**Verified, because it is in this repository:** everything the Flutter client
requires. The repository interfaces, models, query parameters and JSON the
existing parsers expect are all read directly from the code, and are stated here
as fact.

**Not verified, because it is not in this repository:** anything about Koha
itself. There is no Koha source, no Juno source, and no VM access here. A prior
investigation searched for a custom Koha extension and found none — zero `.pm`,
`.pl`, `.kpz` or `.t` files in the working tree, and none in git history on any
branch. So the Koha column of every table below comes from **upstream Koha's
documented API, not from your instance**, and each row carries a confidence
marker. Nothing here was observed running.

Two corrections to earlier assumptions, both from the project's own docs:

- **There is no working Koha signup extension.** `AUTHENTICATION.md` states that
  patron creation is manual — a human reads the Firestore document and types the
  details into Koha's staff UI, and *"THIS STEP HAS NO CODE."* The Flutter signup
  writes only to Firestore.
- **Koha username/password login was removed.** Per `README.md`, the spec changed
  partway through: Firebase email/password became the real, persistent session
  once a librarian approves the request. `koha_auth_service.dart`,
  `login_screen.dart` and `AuthGate`'s Koha-token check are all still present but
  dormant — nothing routes to them. This is why `SessionRepository.establishWithPassword`
  currently has no reachable caller.

The second point sets the direction for Stage 2: **Firebase is the identity
provider, and Juno's job is to turn a Firebase ID token into authorized access to
one specific Koha patron.** Koha's own password login is legacy.

## Confidence markers

| Marker | Meaning |
| --- | --- |
| **Client-verified** | Read from this codebase. Reliable. |
| **Upstream-documented** | Exists in upstream Koha's REST API. Path and shape still need confirming against your version. |
| **Version-dependent** | Exists in some Koha versions only, or the path changed between versions. Confirm first. |
| **Likely absent** | Probably not available as a REST endpoint at all. Juno needs another mechanism. |
| **Undecided** | Nobody has chosen yet. Needs a decision, not an investigation. |

---

## 1. What the client requires

Every network-backed operation the app needs, taken from the repository
interfaces. This is the complete demand side — Juno needs to satisfy exactly
this list and nothing more.

| # | Client call | Returns | Status in app |
| --- | --- | --- | --- |
| C1 | `CatalogRepository.search(query, index, page, perPage)` | `CatalogSearchResult` | REST implemented, inactive |
| C2 | `CatalogRepository.getBiblio(id)` | `CatalogItem` + holdings | REST implemented, inactive |
| C3 | `CatalogRepository.featured()` | `List<CatalogItem>` | REST placeholder |
| C4 | `PatronRepository.getPatron()` | `Patron` | Mock only |
| C5 | `PatronRepository.getLoans()` | `List<Loan>` | Mock only |
| C6 | `PatronRepository.getHolds()` | `List<Hold>` | Mock only |
| C7 | Session establishment | Juno JWT + patron identity | Planned (`/juno/login`) |
| C8 | Renew a loan | — | UI button exists, disabled |
| C9 | Place / cancel a hold | — | Not built |

`SearchHistoryRepository` is deliberately absent: it is device-local state with
no remote equivalent.

C8 and C9 are listed because the roadmap and the disabled Renew button commit to
them. They are out of scope for Stage 2 but shape the Juno design, so they should
not be discovered late.

---

## 2. Mapping table

Flutter → Juno → Koha. The Juno column names the endpoints the client already
calls or is designed to call; the Koha column is what Juno must call to answer.

| # | Flutter | Juno | Koha endpoint(s) | Juno's job |
| --- | --- | --- | --- | --- |
| C1 | `search()` | `GET /api/v1/juno/search` | **No direct equivalent.** Search backend (Elasticsearch/Zebra) or SRU | **Custom logic** |
| C2 | `getBiblio(id)` | `GET /api/v1/juno/biblios/{id}` | `GET /biblios/{id}` + `GET /biblios/{id}/items` + `GET /libraries` | **Aggregate + MARC mapping** |
| C3 | `featured()` | `GET /api/v1/juno/featured` | None | **Custom** — or drop, see §4 |
| C4 | `getPatron()` | *TBD, not yet named in code* | `GET /patrons/{patron_id}` + `GET /libraries` | Aggregate (branch name) |
| C5 | `getLoans()` | *TBD* | `GET /checkouts?patron_id=` + `GET /biblios/{id}` per loan | **Aggregate (N+1)** |
| C6 | `getHolds()` | *TBD* | `GET /holds?patron_id=` + `GET /biblios/{id}` per hold + `GET /libraries` | **Aggregate (N+1)** |
| C7 | session | `POST /api/v1/juno/login` | `GET /patrons?email=` (or a stored mapping) | **Custom — Firebase verify + identity mapping** |
| C8 | renew | *TBD* | `POST /checkouts/{id}/renewals` | Pass-through + ownership check |
| C9 | hold | *TBD* | `POST /holds`, `DELETE /holds/{id}` | Pass-through + ownership check |

Only C8 and C9 are close to pass-through. **Everything the app displays today
requires Juno to aggregate or transform**, which is the main finding of this
plan: Juno is not a proxy, it is an adapter with real logic in it.

---

## 3. Koha endpoints in detail

### K1 · `POST /api/v1/auth/password/validation` — validate a password

- **Confidence:** **Version-dependent.** The app currently calls
  `POST /api/v1/auth/password`, which may not be the correct path. Upstream Koha
  uses `/auth/password/validation`. **Verify which exists on the VM.**
- **Method / auth:** `POST`; no auth — this call produces the credential.
- **Body:** the app sends form-encoded `userid` + `password`.
- **Expected JSON:** the app reads `access_token` or `token`, and `patron_id` or
  `borrowernumber`. `AUTHENTICATION.md` records that these key names were never
  confirmed against a real response. Upstream's validation endpoint returns the
  patron object rather than a token, so **the app's assumption may be wrong in
  kind, not just in spelling.**
- **Model match:** no model; read inline in `KohaAuthService`.
- **Relevance to Stage 2:** **low.** This path is dormant (see preamble). Do not
  invest in it unless you intend to revive Koha password login.

### K2 · Catalog search

- **Confidence:** **Likely absent.** Koha's REST API historically exposes no
  general catalog search route. Search in Koha goes through Zebra or
  Elasticsearch, driven by the OPAC/staff UI, SRU, or Z39.50.
- **Consequence:** this is the **single largest piece of custom work in Stage 2.**
  Juno must reach the search backend directly (Elasticsearch index, or SRU/Z39.50
  against Zebra) and then build result objects itself. There is no endpoint to
  forward to.
- **Must verify on the VM:** which search engine is configured; whether
  Elasticsearch is reachable and under what index name; whether SRU/Z39.50 is
  enabled and on which port.
- **What the client needs back** (`CatalogSearchResult.fromJson`, client-verified):

  ```json
  { "results": [ /* item objects, no holdings */ ],
    "page": 1, "perPage": 20, "totalResults": 137, "hasMore": true }
  ```

  Note the casing trap already recorded in the API contract: the request sends
  `per_page` (snake) while the response is read as `perPage` (camel). Juno must
  respond in **camelCase** to match the parser, or the client changes — and this
  fails silently as a pagination bug rather than an error.

### K3 · `GET /api/v1/biblios/{biblio_id}` — one bibliographic record

- **Confidence:** **Upstream-documented**, but **the response is MARC, not
  friendly JSON.** Depending on `Accept`, Koha returns MARCXML,
  `application/marc-in-json`, or plain text.
- **Auth:** staff permission required (catalogue-level). Some versions expose a
  public variant under `/api/v1/public/biblios/{id}` — **verify.**
- **Transformation required — this is the bulk of Juno's catalog work.** Every
  field in `CatalogItem` must be extracted from MARC:

  | `CatalogItem` field | Likely MARC source | Notes |
  | --- | --- | --- |
  | `id` | biblionumber | Integer in Koha, **string** in the model. Stringify; do not mint new ids. |
  | `title` | `245$a` (+ `$b`) | Strip ISBD punctuation (`/`, `:`, trailing `.`). |
  | `author` | `100$a`, else `245$c` | Koha has no single "author" field. |
  | `publisher` | `264$b`, else `260$b` | |
  | `year` | `264$c` / `260$c` | **String → int.** Strip `[]`, `c`, `?`. Model wants `int?`. |
  | `isbn` | `020$a` | Often has qualifiers ("(pbk.)"). Normalise. |
  | `itemType` | `942$c`, or item-level `itype` | Code → description needs `/item_types`. |
  | `summary` | `520$a` | |
  | `language` | `008/35-37`, or `041$a` | 3-letter code → name if you want it readable. |
  | `subjects` | `650$a` (repeating) | Model wants `List<String>`. |
  | `availableCount` / `totalCount` | **Not in MARC** | Derived from K4. |
  | `holdings` | **Not in MARC** | From K4. |

  Every field except `id` and `title` may be omitted — the model factories
  default them — so Juno can ship a partial record rather than blocking on the
  hard ones.

### K4 · `GET /api/v1/biblios/{biblio_id}/items` — copies of a record

- **Confidence:** **Upstream-documented.** Confirm the exact path; some versions
  prefer `GET /items?biblio_id=`.
- **Auth:** staff permission.
- **Feeds:** `CatalogHolding` plus the availability counts on `CatalogItem`.
- **Transformation:**

  | `CatalogHolding` field | Koha source | Notes |
  | --- | --- | --- |
  | `itemId` | `item_id` | Stringify. |
  | `library` | `holding_library_id` / `home_library_id` | **A branchcode, not a name.** Resolve via K7. |
  | `callNumber` | `callnumber` | |
  | `availability` | derived | See below. |
  | `dueDate` | `onloan` / due date | ISO-8601. Only meaningful when checked out. |

  `ItemAvailability.fromApi` accepts exactly `available`, `checked_out`,
  `reference` and reads **anything else as unavailable** rather than failing.
  Juno must collapse Koha's wider item state (`onloan`, `notforloan`,
  `itemlost`, `withdrawn`, `damaged`, `restricted`) into those three strings.
  Suggested rule, to be confirmed against how your library actually uses the
  fields: `onloan` set → `checked_out`; `notforloan` positive → `reference`;
  lost / withdrawn / damaged → anything else (reads as unavailable); otherwise
  `available`.

  `availableCount` = items resolving to `available`; `totalCount` = all items.
  Deriving both server-side matters — the model comments note that two sources
  for the same fact is how they end up disagreeing.

### K5 · `GET /api/v1/checkouts?patron_id={id}` — current loans

- **Confidence:** **Upstream-documented.** Confirm the parameter name
  (`patron_id` vs `borrowernumber`) and whether returned-item filtering is
  default or explicit.
- **Auth:** staff permission (`circulate`).
- **Transformation into `Loan`:**

  | `Loan` field | Koha source | Notes |
  | --- | --- | --- |
  | `id` | `checkout_id` | Stringify. |
  | `biblioId` | `biblio_id` | Present on the checkout, or via `item_id`. |
  | `title`, `author` | **Not present** | Requires K3 per loan → **N+1**. |
  | `dueDate` | `due_date` | ISO-8601 → `DateTime`. Required, non-null. |

  **Do not send a status.** `LoanStatus` is derived client-side from `dueDate`
  (overdue / within 3 days / active) and there is no field for it. Any status
  Koha sends will be ignored.

  The N+1 is the design decision here: either Juno fans out per loan and caches,
  or it uses a bulk biblio lookup if one exists. **Verify whether the checkouts
  endpoint can embed biblio data** (Koha supports an `x-koha-embed` header on
  some routes) — that would remove the problem entirely and is worth checking
  first.

### K6 · `GET /api/v1/holds?patron_id={id}` — outstanding holds

- **Confidence:** **Upstream-documented.** Confirm parameter naming.
- **Auth:** staff permission (`reserveforothers` or equivalent).
- **Transformation into `Hold`:**

  | `Hold` field | Koha source | Notes |
  | --- | --- | --- |
  | `id` | `hold_id` | Stringify. |
  | `biblioId` | `biblio_id` | |
  | `title`, `author` | **Not present** | K3 per hold → **N+1**, as with loans. |
  | `queuePosition` | `priority` | **Send `null`, not `0`,** once ready for pickup. |
  | `pickupLibrary` | `pickup_library_id` | Branchcode → name via K7. |
  | `status` | `found` | See the trap below. |

  > **Terminology trap — this will cause a real bug if missed.** Koha's `found`
  > value `W` means **"waiting on the hold shelf"**, i.e. *ready for collection*.
  > Our `HoldStatus.waiting` means the opposite: **still in the queue, nothing
  > allocated**. The correct mapping is `found = 'W'` →
  > `HoldStatus.readyForPickup`; `found = 'T'` (in transit) →
  > `HoldStatus.inTransit`; `found` empty/null → `HoldStatus.waiting`.
  > Mapping Koha's `W` to our `waiting` would tell students their book is not
  > ready when it is sitting on the shelf.

### K7 · `GET /api/v1/libraries` — branch codes to names

- **Confidence:** **Upstream-documented.** A public variant
  (`/api/v1/public/libraries`) exists in some versions — **verify.**
- **Auth:** likely none or minimal for the public variant.
- **Why it is needed:** three separate model fields hold human-readable library
  names — `CatalogHolding.library`, `Hold.pickupLibrary`,
  `Patron.homeLibrary` — and Koha returns **branchcodes** in all three places.
  Juno should fetch this once and cache it; it changes almost never.

### K8 · `GET /api/v1/patrons/{patron_id}` — the patron record

- **Confidence:** **Upstream-documented.**
- **Auth:** staff permission (`borrowers`). This is a privileged endpoint — see
  §5 on why that matters.
- **Transformation into `Patron`:**

  | `Patron` field | Koha source | Notes |
  | --- | --- | --- |
  | `name` | `firstname` + `surname` | Join; Koha has no single display name. |
  | `barcode` | `cardnumber` | The model's doc already says this is Koha's `cardnumber`. |
  | `email` | `email` | |
  | `homeLibrary` | `library_id` | Branchcode → name via K7. |

  All four are non-null in the model, so Juno must supply something for each. A
  patron with no email in Koha will need a fallback decision.

### K9 · `GET /api/v1/patrons?email={email}` — find a patron by email

- **Confidence:** **Upstream-documented** as a query on the patrons list;
  confirm the parameter and whether it does exact matching.
- **Why it matters:** this is the most likely answer to the identity problem in
  §5 — it is how Juno could discover a borrowernumber from a Firebase email.

### K10 · `POST /api/v1/checkouts/{checkout_id}/renewals` — renew (future, C8)

- **Confidence:** **Version-dependent.** Older versions used
  `PUT /checkouts/{id}`.
- Out of scope for Stage 2. Listed because the Renew button already exists,
  disabled, and this is the endpoint behind it.

### K11 · `POST /api/v1/holds`, `DELETE /api/v1/holds/{hold_id}` — place / cancel (future, C9)

- **Confidence:** **Upstream-documented.**
- Out of scope for Stage 2. Both are writes on behalf of a student, so both need
  the ownership check in §5.

### K12 · Koha API authentication for Juno itself

- **Confidence:** **Version-dependent and syspref-gated.** Upstream Koha offers
  Basic auth (gated by the `RESTBasicAuth` system preference) and OAuth2 client
  credentials via `POST /api/v1/oauth/token` (gated by
  `RESTOAuth2ClientCredentials`).
- **Must verify:** which of these is enabled on the VM, and which permissions the
  API account holds. Every endpoint from K3 to K11 is privileged.

---

## 4. Where Juno must do more than forward

Sorted by how much work each represents.

**Custom logic, no Koha endpoint to call:**

- **Search (C1).** No REST equivalent. Juno must talk to Elasticsearch or
  SRU/Z39.50 and construct results, including relevance ordering and the
  `page` / `perPage` / `totalResults` / `hasMore` envelope the client parses.
- **Session establishment (C7).** Verify a Firebase ID token, resolve it to a
  borrowernumber, mint a Juno JWT. Firebase token verification needs the Admin
  SDK or equivalent JWKS validation.
- **`featured()` (C3).** No Koha concept corresponds to this. The client code
  already records that the shelf was always intended to become "recently
  viewed", which would be **device-local state and no endpoint at all**.
  **Recommendation: decide this before building anything server-side** — it may
  delete a requirement rather than add one.

**Aggregation across multiple Koha calls:**

- **`getBiblio` (C2):** K3 + K4 + K7, plus full MARC extraction.
- **`getLoans` (C5)** and **`getHolds` (C6):** the list endpoint plus a biblio
  lookup per row, because Koha's circulation records carry no title. Check
  `x-koha-embed` first; it may collapse this.
- **`getPatron` (C4):** K8 + K7.

**Near pass-through:** only the future writes, K10 and K11.

---

## 5. Identity: the blocking design problem

**Nothing today connects a Firebase user to a Koha borrowernumber, and no code
anywhere creates that link.** Patron creation is manual and undocumented in
data terms: a human retypes a Firestore document into Koha's staff UI. Nothing
writes the resulting borrowernumber back anywhere the app or Juno can read.

Every patron-facing endpoint (C4, C5, C6, C8, C9) depends on resolving this, so
it blocks more of Stage 2 than any Koha question does. Three candidate
approaches, all **Undecided**:

1. **Match on email** — Juno calls K9 with the Firebase email. Cheapest; needs no
   new storage and no change to the manual process. Fails when the Koha record's
   email differs from the Firebase one, which the manual retyping step makes
   likely, and silently authorizes the wrong patron if two records share an email.
2. **Store the mapping at approval time** — the librarian records the
   borrowernumber on the Firestore `student_requests` document. Explicit and
   auditable; requires a process change and a dashboard field.
3. **Store the Firebase UID in Koha** — as a patron extended attribute. Keeps the
   authority in Koha, but requires configuring the attribute and adds a step to
   the manual flow.

> **Security note that must not be skipped.** Juno will hold one privileged Koha
> API account and act for many students. It must derive `patron_id` **only** from
> the verified Firebase token via the chosen mapping, and never accept a
> patron/borrower id from the client. Otherwise any signed-in student can read
> any other student's loans by changing a parameter — a textbook confused-deputy
> vulnerability, and the single highest-risk item in this integration.

---

## 6. To verify on the Koha VM

Nothing below can be answered from this repository. Ordered by what blocks the
most.

**Environment**

1. Koha version (`about.pl`) — determines which of K1–K12 exist and under which
   paths.
2. VM hostname/IP, port, and whether HTTPS is configured. Both base URLs in
   `api_constants.dart` are still `REPLACE_WITH_…` placeholders.
3. Reachability from the test device. `AUTHENTICATION.md` already documents the
   LAN-IP and Windows Firewall traps — note that virtual-adapter ranges the phone
   cannot route to are exactly the ranges a VM tends to sit on.

**API access**

4. Is `RESTBasicAuth` enabled? Is `RESTOAuth2ClientCredentials` enabled? Which
   will Juno use?
5. Which permissions does the API account need for `/patrons`, `/checkouts`,
   `/holds`, `/biblios`, `/items`?
6. Which `/api/v1/public/*` routes exist on this version?

**Search — the biggest unknown**

7. Zebra or Elasticsearch? If Elasticsearch: reachable how, and under which index?
8. Is SRU or Z39.50 enabled, and on which port?
9. Does this version expose *any* REST search route? If it does, most of §4's
   custom work disappears.

**Response shapes — capture one real payload each**

10. `POST /auth/password` or `/auth/password/validation` — confirm the path, and
    whether it returns a token at all.
11. `GET /biblios/{id}` — confirm `marc-in-json` is available, and which MARC
    fields your records actually populate. The mapping table in K3 is worthless
    if your cataloguing uses different fields.
12. `GET /biblios/{id}/items` — the real item-status fields, so the collapse into
    `available` / `checked_out` / `reference` matches how the library works.
13. `GET /checkouts?patron_id=` and `GET /holds?patron_id=` — confirm parameter
    names, and the actual `found` values in use for holds.
14. `GET /patrons/{id}` and `GET /libraries` — field names.
15. Does `x-koha-embed` work on checkouts and holds? This single answer decides
    whether C5 and C6 are one call or N+1.
16. Are biblionumbers exposed as plain integers? `CatalogItem.id` is a string;
    the API contract asks that Juno not mint its own ids.

---

## 7. Client-side gaps that block switching to REST

Found while reviewing the code for this plan. None are fixed here — the brief
forbids UI, interface, model and test changes, and forbids switching
`DataSourceConfig`. Recording them so they are not discovered at switch-on.

1. **No token ever reaches the catalog.** `RestCatalogRepository` accepts a
   `tokenProvider`, but `RepositoryRegistry._buildCatalog` constructs it without
   one, and nothing else supplies it. Every catalog request would go out
   **unauthenticated**. Wiring this needs a decision about where the Juno JWT
   lives and who refreshes it.
2. **`per_page` versus `perPage`.** Already in the API contract, repeated because
   it fails silently: the request sends snake_case, the parser reads camelCase.
3. **No `RestPatronRepository` exists.** `RepositoryRegistry` throws on
   `DataSource.rest` for the patron branch, deliberately, and
   `DataSourceConfig.patron` must stay on mock until one is written.
4. **The patron models have no `fromJson`.** Omitted on purpose while no endpoint
   was defined. Whatever §3 settles on, `Patron`, `Loan` and `Hold` each need a
   factory before a REST implementation can parse anything.
5. **`docs/api_contract.md` is now slightly stale.** It describes
   `SessionRepository` as having no implementation and
   `establishWithFirebaseToken` as declared; both changed when the session
   migration landed. Left alone here — the brief marks the API contract as
   do-not-modify.

---

## 8. Suggested order

No code, just sequencing, chosen so the riskiest unknowns fail early rather than
after Juno exists.

1. **Answer §6.1–§6.6** — version and API access. Without these, nothing else can
   be attempted.
2. **Answer §6.7–§6.9 (search).** This is the largest piece of custom work and the
   most likely to invalidate the plan. Find out before building anything.
3. **Decide the identity mapping (§5).** It blocks every patron endpoint and is a
   process decision as much as a technical one, so it needs the most lead time.
4. **Capture real payloads (§6.10–§6.16)** and only then finalise field mappings.
5. **Build Juno read-only, one endpoint at a time**, in the order
   `getBiblio` → `getPatron` → `getLoans` / `getHolds` → `search`. `getBiblio`
   first because it exercises MARC extraction, branch resolution and availability
   collapsing all at once — everything else reuses those three.
6. **Close the client gaps in §7**, then switch `DataSourceConfig` one repository
   at a time. The per-repository constants exist precisely so the catalog can move
   while the patron account stays on mock.
