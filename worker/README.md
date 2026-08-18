# Koha circulation proxy

Closes a real vulnerability found in a security audit of this repo: the
Flutter app used to call Koha's circulation endpoints (checkouts, holds,
fines) directly, using a staff-level Koha account embedded in the app
itself. Koha has no way to restrict that account to "only this one
patron" — so the embedded credential could read or act on **any**
student's records, not just the logged-in one. This Worker holds that
credential instead, verifies who's really calling (a real, currently
signed-in Firebase user), looks up *their own* Koha patron ID itself, and
only ever acts on that. The app can be fully decompiled and it changes
nothing — no patron_id the client sends is ever trusted.

Not deployed or tested yet — this needs your Cloudflare account and your
real Firebase project's service-account key, neither of which I have
access to. Everything below is what deploying it actually involves.

## What you need before deploying

1. **A free Cloudflare account** — [dash.cloudflare.com](https://dash.cloudflare.com), no billing card required for the Workers free tier (100k requests/day).
2. **[Node.js](https://nodejs.org/) + `npm`** on whatever machine you deploy from.
3. **A GCP service account with Firestore read access**, for this Worker's own server-side lookup of "which Koha patron does this Firebase user own" (reads `student_requests`, bypassing `firestore.rules` the way a legitimate server does):
   - Firebase Console → Project Settings → Service Accounts → "Generate new private key" downloads a JSON file. That default one has broad Firebase Admin access; if you want tighter scoping, create a narrower one instead in Google Cloud Console → IAM & Admin → Service Accounts, granted just `Cloud Datastore Viewer` (GCP doesn't support scoping IAM roles down to a single collection, so "read-only, whole project" is as narrow as this gets — still far better than the current staff-level Koha credential shipping in the app).
   - Keep this JSON file somewhere safe — it goes into a Cloudflare *secret* (encrypted, never in a file in this repo), not committed anywhere.
4. **A real, working Koha staff account** for this Worker to use — can be the same rotated `apiuser` account already in `koha_service_account.dart`, or (better, since you're setting this up fresh anyway) a brand new one scoped to only the permissions circulation actually needs (`circulate`, `reserveforothers`, `borrowers` view) rather than whatever `apiuser` currently has.

## Deploying

```bash
cd worker
npm install

# One-time login — opens a browser to authorize wrangler against your
# Cloudflare account.
npx wrangler login

# Secrets — prompted for the value, never shown again, never stored in
# this repo or in wrangler.toml.
npx wrangler secret put KOHA_STAFF_PASSWORD
npx wrangler secret put GCP_SERVICE_ACCOUNT_JSON   # paste the ENTIRE downloaded JSON file's contents, one line

npx wrangler deploy
```

`wrangler deploy` prints the Worker's live URL (something like
`https://jzl-koha-proxy.<your-subdomain>.workers.dev`). That's what goes
into the Flutter app's `ApiConstants.circulationProxyBaseUrl`.

Before deploying, edit `wrangler.toml`'s `[vars]` block:
- `KOHA_BASE_URL` — your real Koha URL, reachable from the public internet (this Worker runs on Cloudflare's edge, not your machine — `127.0.0.1`/`10.0.2.2` mean nothing here).
- `FIREBASE_PROJECT_ID` — double-check this still matches your real Firebase project (currently set from what this repo's git history shows, `comsats-library-app`).
- `KOHA_STAFF_USERID` — whichever account you decided on in step 4 above.

## What this does NOT cover yet

- **Search/catalog browsing** (`BiblioService`) still uses the embedded
  Koha credential directly. Deliberately out of scope here — catalog
  data is public-equivalent (the same data the real OPAC website already
  shows anyone), so it doesn't carry the same privacy risk circulation
  data does. Worth revisiting later if you want to remove the embedded
  credential from the app entirely, but it's a smaller, separate change.
- **Rate limiting / abuse protection** on this Worker itself — Cloudflare
  offers this (Workers rate limiting rules) but it's not configured here.
  Worth adding once this is live and you can see real traffic patterns.
- **This has not been run against a live Koha instance.** The route
  logic was written against the exact real Koha REST shapes confirmed
  earlier this session (checkout/hold/account/circulation_rules field
  names, required params like `pickup_library_id`), but there's no
  substitute for actually deploying it and testing login → checkouts →
  place a hold → cancel it end-to-end before trusting it with real
  student data.
