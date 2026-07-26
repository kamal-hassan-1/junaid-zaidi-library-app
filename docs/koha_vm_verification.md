# Koha VM verification checklist

Run these in order, one command at a time, and record each answer. The point is
to replace every "verify on the VM" in `docs/stage2_integration_plan.md` with an
observed fact before any Juno code is written.

No Flutter code, no repositories and no backend code change as a result of this
document. It only asks questions of the VM.

## How the status markers were decided

Every path below was checked against **Koha's official OpenAPI specification**
(`api/v1/swagger/` in the Koha source), so the paths, parameter names and
permissions are quoted, not remembered.

| Marker | Meaning |
| --- | --- |
| **Confirmed** | The endpoint is in Koha's official spec. Expect it to work — the command confirms it exists on *your version* with *your permissions*. |
| **Needs verification** | The endpoint exists, but something we depend on — a field name, a response format, actual data values — is unknown. |
| **Probably unavailable** | No official Koha endpoint provides this. Expect the command to fail; running it documents the gap. |

One correction to the Stage 2 plan, found while checking the spec: **`GET /biblios/{id}`
produces `application/json`, not only MARC.** The plan assumed MARC-only and
budgeted for full MARC extraction. If the JSON representation carries the fields
we need, that assumption was too pessimistic — which is what V7 exists to settle,
and it is the single check most likely to save work.

A second correction: the app calls `POST /api/v1/auth/password`, which **is not in
the spec.** The real path is `POST /api/v1/auth/password/validation` (V5).

## Setup

Run these on the VM over SSH. That avoids confusing an API problem with a
firewall or LAN-routing problem, and `curl` is already there. (The host-machine
traps are documented in `AUTHENTICATION.md` — note that a VM typically sits on
exactly the virtual-adapter ranges a phone cannot route to.)

```bash
# Adjust to your instance. Koha usually serves the staff interface and the OPAC
# on different ports; koha-testing-docker uses 8081 and 8080 respectively.
export KOHA_STAFF="http://127.0.0.1:8081"
export KOHA_OPAC="http://127.0.0.1:8080"

# A Koha staff account for the API. See V4 for the permissions it needs.
export API_USER="your_api_user"
export API_PASS="your_api_password"

# Filled in as you go, from V8 and V13.
export BIBLIO_ID=""
export PATRON_ID=""
```

`-i` is on every command deliberately: the status line and headers matter as much
as the body. Add `| jq .` if `jq` is installed.

If you are running from Windows PowerShell instead, use `curl.exe` explicitly and
swap the single quotes for double quotes — PowerShell does not treat single quotes
the way bash does.

---

# Part 1 — Preflight

## V1 · Is the API alive, and on which port?

**Status:** Confirmed · **Auth:** none · **Expect:** `200`

`/public/libraries` is the ideal probe: it is in the spec and requires no
authentication, so a `200` proves the API is mounted and reachable without any
credential question mixed in.

```bash
curl -sS -i "$KOHA_OPAC/api/v1/public/libraries"
curl -sS -i "$KOHA_STAFF/api/v1/public/libraries"
```

**Record:** which port(s) answered. A `404` means the API is not enabled or the
port is wrong; `503` means Koha is in maintenance mode.

## V2 · Which Koha version?

**Status:** Needs verification · **Auth:** varies · **Expect:** `200`

Every marker below is version-sensitive, so this is the first real answer needed.

```bash
# Fastest, if this route exists on your version:
curl -sS -i "$KOHA_STAFF/api/v1/status"

# Authoritative fallback, on the VM:
dpkg -l | grep koha-common
```

**Record:** the exact version (e.g. 24.05). Also readable in the staff interface
under **About Koha**.

## V3 · Is REST authentication switched on?

**Status:** Confirmed · **Auth:** staff account · **Expect:** `200`

Koha gates API authentication behind system preferences. If `RESTBasicAuth` is
off, every authenticated command below fails no matter what credentials you use —
so check this before concluding an endpoint is missing.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/sysprefs?_per_page=100" \
  -G --data-urlencode 'q={"variable":{"like":"REST%"}}'
```

**Record:** the values of `RESTBasicAuth` and `RESTOAuth2ClientCredentials`.
Both are also visible in **Administration → Global system preferences → search
"REST"**, which is the more reliable route if this command 403s.

## V4 · Does the API account authenticate, and what can it do?

**Status:** Confirmed · **Auth:** basic · **Expect:** `200`

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/libraries?_per_page=3"
```

`401` means the credential or `RESTBasicAuth` is wrong; `403` means the account
authenticated but lacks permission. From the spec, the account needs:

| Permission | Unlocks |
| --- | --- |
| `catalogue` | biblios, items, libraries, item types |
| `circulate: circulate_remaining_permissions` | checkouts |
| `reserveforothers: place_holds` | reading holds |
| `reserveforothers: "1"` | placing holds |
| `borrowers: list_borrowers` | patron lookup |

**Record:** whether basic auth works, and which of the five permissions the
account holds.

## V5 · Password validation — the path the app currently gets wrong

**Status:** Needs verification · **Auth:** none · **Expect:** `201` on valid, `400` on invalid

The app calls `POST /api/v1/auth/password`, which is not in the spec. The real
path is below. Worth one command to settle whether the dormant `KohaAuthService`
was ever going to work.

```bash
curl -sS -i -X POST \
  -H 'Content-Type: application/json' \
  -d '{"identifier":"some_patron_userid","password":"their_password"}' \
  "$KOHA_STAFF/api/v1/auth/password/validation"
```

**Fields we need:** whether the response contains a token at all. `KohaAuthService`
expects `access_token`/`token` plus `patron_id`/`borrowernumber`; the spec suggests
this endpoint *validates* and returns patron identifiers rather than issuing a
token.

**Maps to:** nothing — read inline in `KohaAuthService`, which is dormant per
`README.md`. Low priority unless you intend to revive Koha password login.

## V6 · OAuth2 client credentials (alternative to basic auth)

**Status:** Confirmed · **Auth:** client id/secret · **Expect:** `200`

Preferable to basic auth for a long-lived service like Juno, if enabled.

```bash
curl -sS -i -X POST \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'grant_type=client_credentials&client_id=YOUR_ID&client_secret=YOUR_SECRET' \
  "$KOHA_STAFF/api/v1/oauth/token"
```

**Record:** whether it returns an `access_token`, and its expiry. Requires
`RESTOAuth2ClientCredentials` on plus an API client configured on a patron.

---

# Part 2 — Bibliographic search

This is the largest open question in the whole integration, and V7 is the one
check that could invalidate the search design.

## V7 · Full-text relevance search

**Status:** **Probably unavailable** · **Expect:** `404`

There is **no `/search` path anywhere in Koha's official spec.** Catalog search in
Koha runs through Zebra or Elasticsearch, driven by the OPAC UI, SRU or Z39.50 —
not the REST API. Run this to document the gap rather than to succeed.

```bash
curl -sS -i -u "$API_USER:$API_PASS" "$KOHA_STAFF/api/v1/search"
```

**Consequence if it 404s (expected):** Juno cannot forward `CatalogRepository.search`
to anything. It must either use V8 below as a limited substitute, or talk to the
search backend directly (Elasticsearch index, or SRU/Z39.50 against Zebra).

**Maps to:** `CatalogSearchResult`.

## V8 · `GET /biblios` with a query filter — the substitute

**Status:** Needs verification · **Auth:** basic, `catalogue` · **Expect:** `200`

The spec does have `listBiblio`, taking `q`, `_match`, `_order_by`, `_page` and
`_per_page`. This is **database attribute filtering, not relevance search** — but
it may be enough for title/author/ISBN lookups, which is most of what students do.

```bash
# Preferred form. The exact operator syntax is the part to verify.
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -G "$KOHA_STAFF/api/v1/biblios" \
  --data-urlencode 'q={"title":{"like":"%algorithm%"}}' \
  --data-urlencode '_per_page=5'

# If the above 400s with `invalid_query`, try exact match:
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -G "$KOHA_STAFF/api/v1/biblios" \
  --data-urlencode 'q={"title":"Introduction to Algorithms"}' \
  --data-urlencode '_per_page=5'
```

**Fields we need:** whether the response is a JSON array of biblio objects, which
fields each carries, and whether the `X-Total-Count` header is returned (that is
what `CatalogSearchResult.totalResults` needs).

**Also verify:** can `q` filter on **ISBN**? ISBN lives in `biblioitems`, not
`biblio`, so it may need dot notation or an embed. Our search UI offers ISBN as one
of four indexes, so this decides whether that chip can work.

**Maps to:** `CatalogSearchResult` → `CatalogItem` per element.

**Record:** does it work; is it fast enough on a real catalogue; can it do
keyword-across-fields at all (probably not — plan for keyword to need the search
backend).

---

# Part 3 — Bibliographic detail

## V9 · `GET /biblios/{biblio_id}` as JSON — the highest-value check

**Status:** Needs verification · **Auth:** basic, `catalogue` · **Expect:** `200`

The spec lists `application/json` among this endpoint's produced types. **If the
JSON carries title/author/publisher/year/ISBN, Juno needs no MARC parsing for the
detail screen** — which removes the largest transformation in the Stage 2 plan.

First get a real biblionumber, then fetch it:

```bash
curl -sS -u "$API_USER:$API_PASS" -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/biblios?_per_page=1"

export BIBLIO_ID="<paste a real biblio_id here>"

curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/biblios/$BIBLIO_ID"
```

**Fields we need**, and where each lands in `CatalogItem`:

| Needed | `CatalogItem` field | Note |
| --- | --- | --- |
| biblionumber | `id` | Integer in Koha, **string** in the model. Stringify; do not mint new ids. |
| title | `title` | Required. May carry ISBD punctuation to strip. |
| author | `author` | |
| publisher | `publisher` | |
| publication year | `year` | Model wants **`int?`** — Koha's is often a string like `c2009.` |
| ISBN | `isbn` | May be absent here (lives in `biblioitems`). |
| item type | `itemType` | Likely a **code**; V16 resolves it to a label. |
| abstract/summary | `summary` | |
| language | `language` | |
| subjects | `subjects` | Model wants `List<String>`. |

Every field except `id` and `title` may be omitted — the model factories default
them — so a partial record is shippable.

**Maps to:** `CatalogItem`.

## V10 · `GET /biblios/{biblio_id}` as MARC — the fallback

**Status:** Confirmed · **Auth:** basic, `catalogue` · **Expect:** `200`

Only needed if V9's JSON is missing fields we require.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/marc-in-json' \
  "$KOHA_STAFF/api/v1/biblios/$BIBLIO_ID"
```

**Fields we need:** confirm which MARC tags **your cataloguing actually populates**
— the mapping table in the Stage 2 plan (245$a, 100$a, 260/264, 020$a, 942$c,
520$a, 650$a) is worthless if this library uses different fields.

**Maps to:** `CatalogItem`, via extraction in Juno.

## V11 · `GET /public/biblios/{biblio_id}`

**Status:** Confirmed · **Auth:** verify — likely none · **Expect:** `200`

If the public variant returns what we need without a privileged account, Juno's
catalog path stops needing staff permissions entirely. That is a meaningful
security simplification.

```bash
curl -sS -i -H 'Accept: application/json' \
  "$KOHA_OPAC/api/v1/public/biblios/$BIBLIO_ID"
```

**Record:** does it need auth, and does its JSON match V9's.

---

# Part 4 — Item availability

## V12 · `GET /biblios/{biblio_id}/items`

**Status:** Confirmed · **Auth:** basic, `catalogue` · **Expect:** `200`

Supplies both the holdings list and the availability counts. `CatalogItem` carries
counts but no status of its own, so both are derived here.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/biblios/$BIBLIO_ID/items"
```

**Fields we need:**

| Needed | `CatalogHolding` field | Note |
| --- | --- | --- |
| `item_id` | `itemId` | Stringify. |
| `holding_library_id` / `home_library_id` | `library` | **A branchcode, not a name** — V15 resolves it. |
| `callnumber` | `callNumber` | |
| `onloan`, `not_for_loan_status`, `lost_status`, `withdrawn`, `damaged_status` | `availability` | Collapsed — see below. |
| due date | `dueDate` | ISO-8601; only meaningful when checked out. |

**The collapse Juno must perform.** `ItemAvailability.fromApi` accepts exactly
`available`, `checked_out` and `reference`, and reads **anything else as
unavailable** rather than failing. Proposed rule, to confirm against how this
library uses the fields: `onloan` set → `checked_out`; not-for-loan positive →
`reference`; lost / withdrawn / damaged → any other string; otherwise
`available`.

`availableCount` = items resolving to `available`; `totalCount` = all items.

**Record:** the real field names on your version, and which status fields your
library actually populates.

**Maps to:** `CatalogHolding`, plus `CatalogItem.availableCount` / `totalCount`.

## V13 · `GET /public/biblios/{biblio_id}/items`

**Status:** Confirmed · **Auth:** verify — likely none · **Expect:** `200`

```bash
curl -sS -i -H 'Accept: application/json' \
  "$KOHA_OPAC/api/v1/public/biblios/$BIBLIO_ID/items"
```

**Record:** whether it exposes the status fields V12 needs. Public endpoints often
return a reduced set.

---

# Part 5 — Libraries and item types

## V14 · `GET /libraries`

**Status:** Confirmed · **Auth:** basic, `catalogue` · **Expect:** `200`

Three separate model fields hold a human-readable library name —
`CatalogHolding.library`, `Hold.pickupLibrary` and `Patron.homeLibrary` — and Koha
returns **branchcodes** in all three places. Fetch once and cache; this changes
almost never.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/libraries"
```

**Fields we need:** `library_id` (the code) and `name`.

**Maps to:** the display strings in `CatalogHolding`, `Hold` and `Patron`.

## V15 · `GET /public/libraries`

**Status:** Confirmed · **Auth:** none · **Expect:** `200`

Already run as V1. Note it here as the no-auth alternative for name resolution.

## V16 · `GET /item_types`

**Status:** Confirmed · **Auth:** basic, `catalogue` · **Expect:** `200`

`CatalogItem.itemType` is documented as a human label ("Books", "Reference"), but
Koha stores a code.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/item_types"
```

**Fields we need:** the code and its description.

**Maps to:** `CatalogItem.itemType`.

---

# Part 6 — Patron

## V17 · `GET /patrons/{patron_id}`

**Status:** Confirmed · **Auth:** basic, `borrowers` · **Expect:** `200`

```bash
curl -sS -u "$API_USER:$API_PASS" -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/patrons?_per_page=1"

export PATRON_ID="<paste a real patron_id here>"

curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/patrons/$PATRON_ID"
```

**Fields we need:**

| Needed | `Patron` field | Note |
| --- | --- | --- |
| `firstname` + `surname` | `name` | Join — Koha has no single display name. |
| `cardnumber` | `barcode` | The model's doc already calls this Koha's `cardnumber`. |
| `email` | `email` | |
| `library_id` | `homeLibrary` | Branchcode → name via V14. |

All four are **non-null** in the model, so Juno must supply something for each.
Decide a fallback now for a patron with no email in Koha.

**Maps to:** `Patron`.

## V18 · `GET /patrons?email=…` — the identity mapping

**Status:** Confirmed · **Auth:** basic, `borrowers: list_borrowers` · **Expect:** `200`

`email` is a documented query parameter with case-insensitive matching. This is the
most likely answer to the blocking identity problem: nothing today links a Firebase
user to a borrowernumber.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -G "$KOHA_STAFF/api/v1/patrons" \
  --data-urlencode 'email=some.student@isbstudent.comsats.edu.pk'
```

**Record, and this matters more than the status code:**

1. Does it match exactly, or substring? (`_match=exact` may be needed.)
2. **Can two patrons share an email?** If yes, matching on email can authorize the
   wrong student, and this approach is unsafe on its own.
3. Do your Koha records' emails actually equal the Firebase ones? The manual
   retyping step in `AUTHENTICATION.md` makes drift likely.

**Maps to:** not a model — this is how Juno resolves which patron a Firebase token
refers to.

---

# Part 7 — Loans

## V19 · `GET /checkouts?patron_id={id}`

**Status:** Confirmed · **Auth:** basic, `circulate: circulate_remaining_permissions` · **Expect:** `200`

`patron_id` is a documented query parameter. Current checkouts are returned by
default; a `checked_in` flag includes returned ones.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/checkouts?patron_id=$PATRON_ID"
```

**Fields we need:**

| Needed | `Loan` field | Note |
| --- | --- | --- |
| `checkout_id` | `id` | Stringify. |
| `biblio_id` | `biblioId` | Or resolve from `item_id`. |
| — | `title`, `author` | **Not on the checkout.** See V20. |
| `due_date` | `dueDate` | ISO-8601 → `DateTime`. **Required, non-null.** |

**Do not send a status.** `LoanStatus` is derived client-side from `dueDate`
(overdue / within 3 days / active) and there is no field for it. Anything Koha
sends is ignored.

**Maps to:** `Loan`.

## V20 · Does `x-koha-embed` work on checkouts?

**Status:** Needs verification · **Auth:** as V19 · **Expect:** `200`

**This one answer decides whether loans are one call or N+1.** The header is
documented as taking a comma-delimited list of relation names, and the spec shows
checkouts accepting an embed header — but which relations are available here is
version-specific.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -H 'x-koha-embed: item,biblio' \
  "$KOHA_STAFF/api/v1/checkouts?patron_id=$PATRON_ID"
```

**Record:** whether `biblio` (and `item`) come back nested, and whether the nested
biblio carries `title` and `author`. If yes, `getLoans` is a single call and the
N+1 in the Stage 2 plan disappears. If it 400s, try `item` alone, then
`item.biblio`.

## V21 · `GET /patrons/{patron_id}/checkouts`

**Status:** Confirmed · **Auth:** basic · **Expect:** `200`

The same data under the patron resource. Worth comparing — it may embed more by
default, and it reads more naturally for a per-patron call.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/patrons/$PATRON_ID/checkouts"
```

## V22 · `GET /public/patrons/{patron_id}/checkouts`

**Status:** Confirmed · **Auth:** the patron's **own** credentials · **Expect:** `200` or `403`

Architecturally interesting: the public namespace lets a patron read their own
data, which would remove Juno's need for a privileged account and with it the
confused-deputy risk flagged in the Stage 2 plan.

```bash
# As the patron themselves, not the API account:
curl -sS -i -u "patron_userid:patron_password" \
  -H 'Accept: application/json' \
  "$KOHA_OPAC/api/v1/public/patrons/$PATRON_ID/checkouts"
```

**Record:** does it work, and does it 403 when the credentials belong to a
*different* patron? (It should.)

**The catch:** our app has no Koha password for the student — Firebase is the
identity. So this is only usable if Juno can obtain a per-patron credential.
Verify anyway; it changes the security design if it is viable.

---

# Part 8 — Holds

## V23 · `GET /holds?patron_id={id}`

**Status:** Confirmed · **Auth:** basic, `reserveforothers: place_holds` · **Expect:** `200`

The spec documents query parameters for `patron_id`, `biblio_id`, `item_id`,
`pickup_library_id`, `priority` and `found`.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/holds?patron_id=$PATRON_ID"
```

**Fields we need:**

| Needed | `Hold` field | Note |
| --- | --- | --- |
| `hold_id` | `id` | Stringify. |
| `biblio_id` | `biblioId` | |
| — | `title`, `author` | **Not on the hold.** Same N+1 as loans; see V24. |
| `priority` | `queuePosition` | **Send `null`, not `0`,** once ready for pickup. |
| `pickup_library_id` | `pickupLibrary` | Branchcode → name via V14. |
| `found` | `status` | See the trap below. |

> **Terminology trap — this will cause a real bug if missed.** Koha's `found` value
> `W` means **"waiting on the hold shelf"**, i.e. *ready for collection*. Our
> `HoldStatus.waiting` means the opposite: **still in the queue, nothing
> allocated**. Correct mapping: `found = 'W'` → `readyForPickup`; `found = 'T'`
> (in transit) → `inTransit`; `found` empty/null → `waiting`. Mapping Koha's `W`
> onto our `waiting` would tell students their book is not ready while it sits on
> the shelf.

**Maps to:** `Hold`.

## V24 · Does `x-koha-embed` work on holds?

**Status:** Needs verification · **Auth:** as V23 · **Expect:** `200`

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -H 'x-koha-embed: biblio' \
  "$KOHA_STAFF/api/v1/holds?patron_id=$PATRON_ID"
```

**Record:** as V20 — whether the nested biblio carries `title` and `author`.

## V25 · Which `found` values does this library actually use?

**Status:** Needs verification · **Auth:** as V23 · **Expect:** `200`

A data question, not an API question, and the mapping in V23 depends on it.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -G "$KOHA_STAFF/api/v1/holds" --data-urlencode 'found=W'

curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  -G "$KOHA_STAFF/api/v1/holds" --data-urlencode 'found=T'
```

**Record:** which values appear in practice, and whether any third value shows up
that our three-case `HoldStatus` cannot represent.

---

# Part 9 — Renewals

> **Everything from here changes data.** Do these last, against a throwaway patron
> and a throwaway loan on a test record, never against a real student's account.

## V26 · `GET /checkouts/{checkout_id}/allows_renewal`

**Status:** Confirmed · **Auth:** basic, `circulate` · **Expect:** `200`

Read-only and safe. Tells you whether a renewal would succeed and why not — which
is exactly what the disabled Renew button needs in order to become enabled
intelligently rather than optimistically.

```bash
export CHECKOUT_ID="<a checkout_id from V19>"

curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/checkouts/$CHECKOUT_ID/allows_renewal"
```

**Fields we need:** whether renewal is allowed, and the reason if not (too many
renewals, item on hold for someone else, patron blocked).

**Maps to:** nothing yet — would drive the Renew button's enabled state.

## V27 · `POST /checkouts/{checkout_id}/renewals` — **write**

**Status:** Confirmed · **Auth:** basic, `circulate` · **Expect:** `201`

```bash
curl -sS -i -X POST -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/checkouts/$CHECKOUT_ID/renewals"
```

**Record:** the new `due_date` in the response, and the error shape on refusal.
Note the spec also lists a singular `/renewal` path — if this 404s, try that;
which one exists is version-dependent.

**Maps to:** would refresh `Loan.dueDate`.

## V28 · `/public/patrons/{patron_id}/self_renewal` — **write**

**Status:** Needs verification · **Auth:** the patron's own credentials · **Expect:** `201`

In the spec but its method and semantics need confirming. Relevant for the same
reason as V22: self-service renewal without a privileged account.

```bash
curl -sS -i -X POST -u "patron_userid:patron_password" \
  -H 'Accept: application/json' \
  "$KOHA_OPAC/api/v1/public/patrons/$PATRON_ID/self_renewal"
```

---

# Part 10 — Reservations

> Still writes. Same caution as Part 9.

## V29 · `GET /biblios/{biblio_id}/pickup_locations`

**Status:** Confirmed · **Auth:** basic · **Expect:** `200`

Read-only. Must be called before placing a hold — not every branch is a valid
pickup location for every record, so the app cannot simply offer all libraries.

```bash
curl -sS -i -u "$API_USER:$API_PASS" \
  -H 'Accept: application/json' \
  "$KOHA_STAFF/api/v1/biblios/$BIBLIO_ID/pickup_locations"
```

**Maps to:** the eventual pickup-library picker; constrains `Hold.pickupLibrary`.

## V30 · `POST /holds` — **write**

**Status:** Confirmed · **Auth:** basic, `reserveforothers: "1"` · **Expect:** `201`

```bash
curl -sS -i -X POST -u "$API_USER:$API_PASS" \
  -H 'Content-Type: application/json' \
  -d "{\"patron_id\":$PATRON_ID,\"biblio_id\":$BIBLIO_ID,\"pickup_library_id\":\"YOUR_BRANCHCODE\"}" \
  "$KOHA_STAFF/api/v1/holds"
```

**Record:** the exact required body fields (the spec has a request schema —
confirm against your version), the created `hold_id`, and the error shape when the
patron already holds the record or has hit their hold limit.

**Maps to:** would create a `Hold`.

## V31 · `DELETE /holds/{hold_id}` — **write**

**Status:** Confirmed · **Auth:** basic · **Expect:** `204`

```bash
export HOLD_ID="<the hold_id created in V30>"

curl -sS -i -X DELETE -u "$API_USER:$API_PASS" \
  "$KOHA_STAFF/api/v1/holds/$HOLD_ID"
```

Clean up the hold you just created.

## V32 · `DELETE /public/patrons/{patron_id}/holds/{hold_id}` — **write**

**Status:** Confirmed · **Auth:** the patron's own credentials · **Expect:** `204`

The patron cancelling their own hold. Same architectural note as V22 and V28.

```bash
curl -sS -i -X DELETE -u "patron_userid:patron_password" \
  "$KOHA_OPAC/api/v1/public/patrons/$PATRON_ID/holds/$HOLD_ID"
```

---

# Results to record

Fill this in as you go. These answers are what the Juno design depends on.

| # | Check | Status | Answer / notes |
| --- | --- | --- | --- |
| V1 | API reachable, which port | | |
| V2 | Koha version | | |
| V3 | `RESTBasicAuth` / OAuth2 sysprefs | | |
| V4 | API account permissions | | |
| V5 | `auth/password/validation` shape | | |
| V6 | OAuth2 token works | | |
| V7 | Relevance search exists | | expect no |
| V8 | `GET /biblios?q=` usable; ISBN filterable | | |
| V9 | Biblio JSON has the fields we need | | **decides MARC or not** |
| V10 | MARC tags your library populates | | |
| V11 | Public biblio endpoint usable | | |
| V12 | Item status field names | | |
| V13 | Public items endpoint usable | | |
| V14 | Branchcode → name | | |
| V16 | Item type code → label | | |
| V17 | Patron field names | | |
| V18 | Email lookup exact? emails unique? | | **blocks identity** |
| V19 | Checkout field names | | |
| V20 | Embed works on checkouts | | **decides N+1** |
| V22 | Public checkouts as patron | | |
| V23 | Hold field names | | |
| V24 | Embed works on holds | | |
| V25 | Real `found` values | | |
| V26 | Renewal eligibility available | | |
| V27 | Renewal write works | | |
| V29 | Pickup locations | | |
| V30 | Hold creation body | | |

## The four answers that change the plan

1. **V9** — if the biblio JSON is sufficient, the MARC extraction work in the
   Stage 2 plan is unnecessary.
2. **V20 / V24** — if embed works, loans and holds are one call each instead of
   N+1.
3. **V8** — if `q` filtering covers title, author and ISBN adequately, search may
   not need Elasticsearch or SRU at all. Keyword-across-fields probably still will.
4. **V18** — if emails are not reliably unique and matching Firebase, the identity
   mapping must move to storing the borrowernumber at approval time, which is a
   process change and needs the most lead time.
