# API Contract

Every network endpoint the Flutter app references, derived solely from the current
codebase. Nothing here is aspirational unless the code itself says so: each row
names the file it was read from, and anything the code leaves undecided is marked
TBD rather than filled in with a guess.

Two things to know before reading. **No endpoint in this document is reachable
today** — both base URLs are `REPLACE_WITH_…` placeholders, and the catalog runs
on `MockCatalogRepository` because `DataSourceConfig.catalog` is `DataSource.mock`.
And the app talks to two different backends: Koha directly for password login, and
a custom "Juno" proxy for everything catalog-related.

## Status legend

| Status | Meaning |
| --- | --- |
| **Implemented** | Request construction and response parsing exist in Dart and are covered by tests. |
| **Placeholder** | Code exists, but the path and/or response shape is a stand-in marked with a TODO. Must be confirmed before use. |
| **Planned** | Named in code as an agreed design decision, with no implementation yet. |
| **TBD** | A detail required to call the endpoint is undecided. |

## Base URLs

Both live in `lib/config/api_constants.dart`, which is the only place in the app
permitted to hold a URL.

| Constant | Value | Purpose |
| --- | --- | --- |
| `kohaBaseUrl` | `https://REPLACE_WITH_YOUR_KOHA_URL` | Koha itself. Used only for password login. |
| `junoBaseUrl` | `https://REPLACE_WITH_YOUR_JUNO_API_URL` | The custom backend proxying Koha, serving `/api/v1/juno/*`. |

## Endpoints

| # | Method | Path | Auth required | Parsed by | Consumed by | Status |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `POST` | `{kohaBaseUrl}/api/v1/auth/password` | No — this is what issues the credential | None (inline `Map` read) | `LoginScreen` | **Implemented** |
| 2 | `GET` | `{junoBaseUrl}/api/v1/juno/search` | Bearer, when a token provider is supplied | `CatalogSearchResult.fromJson` | `OpacSearchScreen` | **Implemented**, inactive |
| 3 | `GET` | `{junoBaseUrl}/api/v1/juno/biblios/{id}` | Bearer, when a token provider is supplied | `CatalogItem.fromJson` | `BookDetailScreen` | **Implemented**, inactive |
| 4 | `GET` | `{junoBaseUrl}/api/v1/juno/featured` | Bearer, when a token provider is supplied | `CatalogItem.fromJson` per element | `OpacSearchScreen` landing shelf | **Placeholder** |
| 5 | `POST` | `{junoBaseUrl}/api/v1/juno/login` | No — exchanges a Firebase ID token | None yet | Nothing yet | **Planned** |

---

### 1. `POST /api/v1/auth/password` — Koha password login

*Source: `lib/services/koha_auth_service.dart`, `lib/config/api_constants.dart`*

Koha's own login. The comment in `login_screen.dart` states the intent plainly:
real logins go through Koha, and Firebase's role stops at email verification.

- **Authentication:** none required; this call produces the session.
- **Query parameters:** none.
- **Request body:** `application/x-www-form-urlencoded`

  | Field | Type | Notes |
  | --- | --- | --- |
  | `userid` | string | Koha username |
  | `password` | string | |

- **Expected response:** JSON object. The code reads two keys, each with a
  fallback, because the exact shape was not known when it was written:

  ```json
  {
    "access_token": "…",
    "patron_id": "…"
  }
  ```

  `token` is accepted in place of `access_token`, and `borrowernumber` in place of
  `patron_id`. A comment marks this as needing confirmation against a real
  response body. **TBD.**

- **Parsed by:** no model. `KohaAuthService` reads the map inline and hands
  `token` plus `patronId` to `SecureStorageService.saveSession`.
- **Status handling:** `401`/`403` → "Incorrect username or password."; any other
  non-`200`/`201` → a message naming the status code; unparseable body →
  "Unexpected response from the library server."
- **Consumed by:** `LoginScreen`. `AuthGate` and `ProfileLoader` call
  `isLoggedIn()`, which reads secure storage rather than the network.

> **Warning.** `KohaAuthService.login` short-circuits on hardcoded credentials
> (`testuser` / `test1234` → patron `0000`) *before* any request is made, so the
> app is reachable with no server at all. The code marks this `TEMP —` and
> `REMOVE before shipping`.

---

### 2. `GET /api/v1/juno/search` — Catalog search

*Source: `lib/repositories/rest/rest_catalog_repository.dart`; sketched earlier in
`lib/repositories/catalog_repository.dart` and `lib/data/search_indexes.dart`*

- **Authentication:** `Authorization: Bearer <token>` is attached when the
  injected `tokenProvider` returns a non-empty token; otherwise the request is
  sent unauthenticated. Every request sends `Accept: application/json`. Whether
  the endpoint *requires* the token is **TBD** — the agreed architecture says yes,
  but nothing enforces it client-side.
- **Query parameters:**

  | Name | Type | Notes |
  | --- | --- | --- |
  | `q` | string | Trimmed. A blank query is answered locally with an empty result and no request. |
  | `index` | enum | `SearchIndex.apiValue`: `keyword`, `title`, `author`, `isbn` |
  | `page` | int | 1-based |
  | `per_page` | int | Defaults to `defaultCatalogPerPage` (20) |

- **Request body:** none.
- **Expected response:**

  ```json
  {
    "results": [ { "…item object, see endpoint 3…" } ],
    "page": 1,
    "perPage": 20,
    "totalResults": 137,
    "hasMore": true
  }
  ```

  Search results omit `holdings`; `CatalogItem.holdings` is null for them by
  design, and the availability counts are what the results list renders instead.

- **Parsed by:** `CatalogSearchResult.fromJson`, which delegates each element to
  `CatalogItem.fromJson`.
- **Status handling:** `401`/`403` → "session has expired"; any other non-2xx →
  message naming the status code. A `404` here is treated as an ordinary failure,
  *not* a not-found, because a missing search endpoint is a deployment problem
  rather than a record that does not exist.
- **Consumed by:** `OpacSearchScreen`, through the `CatalogRepository` interface.
- **Status:** Implemented and unit-tested against `MockClient`; inactive because
  the registry selects the mock.

---

### 3. `GET /api/v1/juno/biblios/{id}` — One catalog record

*Source: `lib/repositories/rest/rest_catalog_repository.dart`*

- **Authentication:** as endpoint 2.
- **Query parameters:** none. `{id}` is percent-encoded into a single path segment.
- **Request body:** none.
- **Expected response:** one item object, with `holdings` present inline.

  ```json
  {
    "id": "42",
    "title": "…",
    "author": "…",
    "publisher": "…",
    "year": 2009,
    "isbn": "9780262033848",
    "itemType": "…",
    "summary": "…",
    "language": "…",
    "subjects": ["…"],
    "availableCount": 2,
    "totalCount": 5,
    "holdings": [
      {
        "itemId": "…",
        "library": "…",
        "callNumber": "…",
        "availability": "available",
        "dueDate": "2026-08-01T00:00:00Z"
      }
    ]
  }
  ```

  Every field except `id` and `title` may be absent; the model factories default
  them, so the backend can omit what Koha does not hold. `availability` is one of
  `available`, `checked_out`, `reference` — any other value is read as
  *unavailable* rather than rejected, which lets the backend pass Koha's wider
  status set through untranslated. `dueDate` is ISO-8601 and only meaningful for
  checked-out copies.

- **Parsed by:** `CatalogItem.fromJson`, which delegates to
  `CatalogHolding.fromJson` and `ItemAvailability.fromApi`.
- **Status handling:** this is the only endpoint where `404` carries meaning — it
  becomes `CatalogNotFoundException`, which the detail screen renders as its own
  not-found state rather than an error. Other codes behave as endpoint 2.
- **Consumed by:** `BookDetailScreen`.
- **Status:** Implemented and unit-tested; inactive.

---

### 4. `GET /api/v1/juno/featured` — Landing shelf

*Source: `lib/repositories/rest/rest_catalog_repository.dart` (`_featuredPath`)*

**This endpoint does not exist.** The path is a placeholder carrying a
`TODO(backend)`, and so is the response shape. Both must be confirmed or replaced
before REST is switched on.

- **Authentication:** as endpoint 2.
- **Query parameters:** none sent. Whether it should be scoped or paginated is **TBD.**
- **Request body:** none.
- **Expected response:** assumed to be a bare JSON array of item objects. **TBD** —
  a `{ "results": [...] }` envelope, matching endpoint 2, is equally plausible.

  ```json
  [ { "id": "1", "title": "…" }, { "id": "2", "title": "…" } ]
  ```

- **Parsed by:** `CatalogItem.fromJson` per element.
- **Consumed by:** `OpacSearchScreen`'s landing state, before any search is run.
- **Status:** **Placeholder.** The TODO also records that this may not be a request
  at all — the shelf was always intended to become "recently viewed", which could
  be device-local state instead.

---

### 5. `POST /api/v1/juno/login` — Session establishment

*Source: `lib/repositories/session_repository.dart` (doc comment only)*

The only reference in the codebase is a comment describing the agreed direction:
today the app authenticates via `KohaAuthService` against
`POST /api/v1/auth/password`, and later this endpoint trades a Firebase ID token
for a Juno JWT.

- **Authentication:** none. The Firebase ID token in the request *is* the credential.
- **Query parameters:** **TBD.**
- **Request body:** **TBD.** A Firebase ID token is sent; the field name and
  content type are unspecified.
- **Expected response:** **TBD.** A Juno JWT, and presumably the patron identifier
  that `SessionRepository.establishWithFirebaseToken` is declared to return.
- **Parsed by:** nothing. `SessionRepository` is an interface with no implementation;
  `RepositoryRegistry.session` throws `UnimplementedError` if read.
- **Consumed by:** nothing yet.
- **Status:** **Planned.**

---

## Not HTTP endpoints

These are real network operations, but the SDK owns the wire format, so no path
exists in this codebase to document. Listed for completeness.

| Operation | Mechanism | Source | Consumed by |
| --- | --- | --- | --- |
| Create account, send verification email, email/password sign-in | `firebase_auth` | `lib/services/firebase_auth_service.dart` | `SignupFormScreen`, `EmailLoginScreen` |
| Microsoft/Azure AD sign-in | `firebase_auth` OAuth provider, `tenant` = `ApiConstants.azureTenantId` | `lib/services/firebase_auth_service.dart` | Auth flow |
| `student_requests` — add; query by `email` ordered by `createdAt` desc | `cloud_firestore` | `lib/services/firestore_service.dart` | `SignupFormScreen`, `EmailLoginScreen`, `AuthGate`, `ProfileLoader` |
| `users` — `doc(uid)` set and get, onboarding check | `cloud_firestore` | `lib/services/firestore_service.dart` | Profile and onboarding |
| Session token and patron id storage | `flutter_secure_storage` | `lib/services/secure_storage_service.dart` | `KohaAuthService`, `AuthGate` |

Firestore documents are parsed by `StudentRequest.fromMap` and `AppUser.fromMap`.

Two external URLs are loaded but are not part of any API contract: the Leaflet
assets and OpenStreetMap tile template inside the map WebView
(`lib/services/osm_map_html.dart`), and a Google Maps search link opened via
`url_launcher` (`lib/data/library_location.dart`).

The catalog is currently served by `MockCatalogRepository` from
`lib/data/mock_catalog_data.dart`, with no network involved.

## Open questions

Consolidated from the TBDs above, roughly in the order they will block work.

1. **Both base URLs are placeholders.** `kohaBaseUrl` and `junoBaseUrl` must be set
   before anything can be reached.
2. **`per_page` versus `perPage`.** The search request sends snake_case while
   `CatalogSearchResult.fromJson` reads camelCase from the response. Both were
   written from the existing sketch and they disagree; if the backend is
   consistent in either direction, one side needs changing. This will present as
   a silent pagination bug rather than an error.
3. **The `featured` endpoint** needs a path and response shape, or the feature
   needs rewiring to local state.
4. **Error response bodies.** Failure messages are currently derived from the
   status code alone and ignore the body. If Juno returns structured errors,
   `RestCatalogRepository._failureFor` is the single place to change.
5. **Status-code mapping** beyond `404` and `401`/`403` — rate limiting, expired
   JWT, and a Koha outage behind the proxy are unspecified.
6. **Are Koha biblionumbers passed through?** `CatalogItem.id` is a string;
   biblionumbers are integers. Confirm the proxy does not mint its own ids.
7. **`POST /api/v1/juno/login`** needs its request and response shapes defined.
8. **Koha's login response keys** need confirming against a real response; the
   code accepts two spellings for each field as a hedge.
9. **The hardcoded dev login** in `KohaAuthService` must be removed before release.
