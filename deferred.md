# Deferred

Items intentionally left unresolved for now — revisit when asked.

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
