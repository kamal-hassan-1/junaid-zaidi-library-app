// Junaid Zaidi Library — Koha circulation proxy.
//
// WHY THIS EXISTS: the Flutter app used to call Koha directly using a
// shared staff-level service account embedded in the app itself
// (KohaServiceAccount in lib/config/koha_service_account.dart). Koha's
// permission model has no concept of "this credential may only touch
// patron X" — circulate/reserveforothers-style permissions are
// all-or-nothing at the account level. So anyone who extracted that
// embedded credential (trivial once it leaked in this public repo) could
// call Koha directly with ANY patron_id and read/act on ANY student's
// checkouts, holds, fines, and personal record fields — the app's own
// "only ever send my own patron_id" logic was a client-side promise with
// nothing server-side enforcing it.
//
// This Worker is that missing server-side enforcement. It:
//   1. Verifies the caller is a real, currently-signed-in Firebase user
//      (checks the ID token's signature against Google's public keys —
//      NOT just decoding it, an unverified JWT proves nothing).
//   2. Looks up THAT verified user's own Koha patron_id itself, from
//      Firestore, using a narrow server-side credential the client never
//      sees — it never trusts a patron_id the client sends.
//   3. Forwards the actual Koha call using a staff credential that lives
//      ONLY here (a Cloudflare secret, never shipped in the app), and
//      double-checks ownership on any operation that mutates something
//      (renew, cancel) before forwarding it.
//
// The app can be modified from here to the ground; nothing it sends can
// make this Worker act on someone else's patron record, because the
// patron_id used for every Koha call is resolved HERE, not trusted from
// the request.

import { jwtVerify, createRemoteJWKSet, SignJWT, importPKCS8 } from 'jose';

const FIREBASE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
};

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

// ---------------------------------------------------------------------
// Step 1: verify the caller is really who they say they are.
// ---------------------------------------------------------------------

let jwks; // module-scoped — reused across requests on a warm isolate.

async function verifyFirebaseIdToken(request, env) {
  const authHeader = request.headers.get('Authorization') || '';
  const match = authHeader.match(/^Bearer (.+)$/);
  if (!match) throw new HttpError(401, 'Missing Authorization: Bearer <Firebase ID token>.');

  jwks ??= createRemoteJWKSet(new URL(FIREBASE_JWKS_URL));

  let payload;
  try {
    ({ payload } = await jwtVerify(match[1], jwks, {
      issuer: `https://securetoken.google.com/${env.FIREBASE_PROJECT_ID}`,
      audience: env.FIREBASE_PROJECT_ID,
    }));
  } catch (err) {
    throw new HttpError(401, `Invalid or expired session (${err.message}).`);
  }

  if (!payload.sub) throw new HttpError(401, 'Token has no subject.');
  return payload.sub; // Firebase UID.
}

// ---------------------------------------------------------------------
// Step 2: resolve that UID's OWN Koha patron_id — server-side, never
// trusting anything the client claims.
//
// The link lives on student_requests.firebaseUid / .borrowerNumber (see
// admin-dashboard.html's approveStudentRequest — there is no separate
// `users` collection doing this today, despite what an older,
// no-longer-used functions/index.js draft assumed). This uses a GCP
// service account to read Firestore directly, bypassing firestore.rules
// (the way any legitimate server-side reader would) — that credential
// lives ONLY in this Worker's secrets, never in the app.
// ---------------------------------------------------------------------

let gcpAccessToken; // { token, expiresAt } — module-scoped cache.

async function getGcpAccessToken(env) {
  if (gcpAccessToken && gcpAccessToken.expiresAt > Date.now() + 30_000) {
    return gcpAccessToken.token;
  }

  const serviceAccount = JSON.parse(env.GCP_SERVICE_ACCOUNT_JSON);
  const privateKey = await importPKCS8(serviceAccount.private_key, 'RS256');

  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({
    scope: 'https://www.googleapis.com/auth/datastore.readonly',
  })
    .setProtectedHeader({ alg: 'RS256' })
    .setIssuer(serviceAccount.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!res.ok) {
    throw new HttpError(502, `Could not authenticate to Firestore: ${await res.text()}`);
  }
  const data = await res.json();
  gcpAccessToken = { token: data.access_token, expiresAt: Date.now() + data.expires_in * 1000 };
  return gcpAccessToken.token;
}

async function resolvePatronId(uid, env) {
  const accessToken = await getGcpAccessToken(env);
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery`;

  const body = {
    structuredQuery: {
      from: [{ collectionId: 'student_requests' }],
      where: {
        compositeFilter: {
          op: 'AND',
          filters: [
            { fieldFilter: { field: { fieldPath: 'firebaseUid' }, op: 'EQUAL', value: { stringValue: uid } } },
            { fieldFilter: { field: { fieldPath: 'status' }, op: 'EQUAL', value: { stringValue: 'Approved' } } },
          ],
        },
      },
      orderBy: [{ field: { fieldPath: 'processedAt' }, direction: 'DESCENDING' }],
      limit: 1,
    },
  };

  const res = await fetch(url, {
    method: 'POST',
    headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new HttpError(502, `Firestore lookup failed: ${await res.text()}`);

  const rows = await res.json();
  const doc = rows.find((r) => r.document)?.document;
  const borrowerNumber = doc?.fields?.borrowerNumber?.stringValue;
  if (!borrowerNumber) {
    throw new HttpError(404, 'No approved library account found for this Firebase user.');
  }
  return borrowerNumber;
}

// ---------------------------------------------------------------------
// Step 3: talk to Koha using the staff credential that lives ONLY here.
// ---------------------------------------------------------------------

async function kohaFetch(env, path, { method = 'GET', body } = {}) {
  const basic = btoa(`${env.KOHA_STAFF_USERID}:${env.KOHA_STAFF_PASSWORD}`);
  const res = await fetch(`${env.KOHA_BASE_URL}${path}`, {
    method,
    headers: {
      Authorization: `Basic ${basic}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await res.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    data = text;
  }
  return { status: res.status, data };
}

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

// ---------------------------------------------------------------------
// Routes.
// ---------------------------------------------------------------------

async function handleLogin(request, env) {
  const { username, password } = await request.json();
  if (!username || !password) throw new HttpError(400, 'username and password are required.');

  const { status, data } = await kohaFetch(env, '/api/v1/auth/password/validation', {
    method: 'POST',
    body: { userid: username, password },
  });

  if (status === 400) throw new HttpError(400, 'Incorrect email or password.');
  if (status === 401 || status === 403) {
    throw new HttpError(502, "Library server rejected this Worker's own service account.");
  }
  if (status !== 200 && status !== 201) throw new HttpError(502, `Koha returned ${status}.`);

  const patronId = data?.patron_id ?? data?.cardnumber ?? data?.userid;
  if (!patronId) throw new HttpError(502, 'Unexpected response from the library server.');
  return json({ patron_id: String(patronId) });
}

async function handleFetchCheckouts(uid, env) {
  const patronId = await resolvePatronId(uid, env);
  const { status, data } = await kohaFetch(env, `/api/v1/checkouts?patron_id=${patronId}`);
  if (status !== 200) throw new HttpError(status, 'Could not load checkouts.');
  return json(data);
}

async function handleRenewCheckout(uid, env, checkoutId) {
  const patronId = await resolvePatronId(uid, env);
  // Ownership check — a Koha checkout_id alone doesn't prove it's this
  // patron's. Confirm it's in THEIR checkout list before renewing it.
  const owned = await kohaFetch(env, `/api/v1/checkouts?patron_id=${patronId}`);
  const belongsToCaller = Array.isArray(owned.data) &&
    owned.data.some((c) => String(c.checkout_id) === String(checkoutId));
  if (!belongsToCaller) throw new HttpError(403, 'That checkout does not belong to you.');

  const { status, data } = await kohaFetch(env, `/api/v1/checkouts/${checkoutId}/renewal`, { method: 'POST' });
  if (status !== 200 && status !== 201) throw new HttpError(status, 'Renewal failed.');
  return json(data);
}

async function handleFetchHolds(uid, env) {
  const patronId = await resolvePatronId(uid, env);
  const { status, data } = await kohaFetch(env, `/api/v1/holds?patron_id=${patronId}`);
  if (status !== 200) throw new HttpError(status, 'Could not load holds.');
  return json(data);
}

async function handlePlaceHold(uid, env, request) {
  const patronId = await resolvePatronId(uid, env);
  const { biblio_id, pickup_library_id } = await request.json();
  if (!biblio_id) throw new HttpError(400, 'biblio_id is required.');

  const { status, data } = await kohaFetch(env, '/api/v1/holds', {
    method: 'POST',
    body: {
      // patron_id is NEVER taken from the client — always the
      // server-resolved one, so a hold can only ever be placed as
      // whoever the verified Firebase token belongs to.
      patron_id: Number(patronId),
      biblio_id,
      pickup_library_id: pickup_library_id ?? env.DEFAULT_PICKUP_LIBRARY_ID ?? 'CPL',
    },
  });
  if (status !== 200 && status !== 201) throw new HttpError(status, 'Could not place hold.');
  return json(data);
}

async function handleCancelHold(uid, env, holdId) {
  const patronId = await resolvePatronId(uid, env);
  const owned = await kohaFetch(env, `/api/v1/holds?patron_id=${patronId}`);
  const belongsToCaller = Array.isArray(owned.data) &&
    owned.data.some((h) => String(h.hold_id) === String(holdId));
  if (!belongsToCaller) throw new HttpError(403, 'That hold does not belong to you.');

  const { status } = await kohaFetch(env, `/api/v1/holds/${holdId}`, { method: 'DELETE' });
  if (status !== 200 && status !== 204) throw new HttpError(status, 'Could not cancel hold.');
  return json({ ok: true });
}

async function handleFetchAccount(uid, env) {
  const patronId = await resolvePatronId(uid, env);
  const { status, data } = await kohaFetch(env, `/api/v1/patrons/${patronId}/account`);
  if (status !== 200) throw new HttpError(status, 'Could not load account.');
  return json(data);
}

async function handleCheckoutLimit(uid, env) {
  const patronId = await resolvePatronId(uid, env);
  const patron = await kohaFetch(env, `/api/v1/patrons/${patronId}`);
  if (patron.status !== 200) throw new HttpError(patron.status, 'Could not load patron record.');
  const categoryId = patron.data?.category_id;
  if (!categoryId) return json({ max_issue_qty: null });

  const rules = await kohaFetch(
    env,
    `/api/v1/circulation_rules?rules=maxissueqty&patron_category_id=${categoryId}`,
  );
  if (rules.status !== 200 || !Array.isArray(rules.data) || rules.data.length === 0) {
    return json({ max_issue_qty: null });
  }
  const rule = rules.data.find((r) => r.context?.item_type_id === '*') ?? rules.data[0];
  const raw = rule.maxissueqty;
  return json({ max_issue_qty: raw == null ? null : parseInt(raw, 10) });
}

async function handleItemLookup(env, itemId) {
  // Catalog-level, not patron-sensitive — no ownership check needed,
  // just proxied so the app never needs the embedded Koha credential
  // for anything circulation-related, including this bridge lookup.
  const { status, data } = await kohaFetch(env, `/api/v1/items/${itemId}`);
  if (status !== 200) throw new HttpError(status, 'Item not found.');
  return json(data);
}

// ---------------------------------------------------------------------
// Entry point.
// ---------------------------------------------------------------------

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // /login is the one endpoint that doesn't require a Firebase
      // token — it's how the app finds out if Koha credentials are
      // valid in the first place, mirroring the current app's actual
      // login order (Firebase sign-in happens first, then this).
      if (path === '/login' && request.method === 'POST') {
        return await handleLogin(request, env);
      }

      const uid = await verifyFirebaseIdToken(request, env);

      if (path === '/checkouts' && request.method === 'GET') {
        return await handleFetchCheckouts(uid, env);
      }
      const renewMatch = path.match(/^\/checkouts\/(\d+)\/renewal$/);
      if (renewMatch && request.method === 'POST') {
        return await handleRenewCheckout(uid, env, renewMatch[1]);
      }
      if (path === '/holds' && request.method === 'GET') {
        return await handleFetchHolds(uid, env);
      }
      if (path === '/holds' && request.method === 'POST') {
        return await handlePlaceHold(uid, env, request);
      }
      const holdMatch = path.match(/^\/holds\/(\d+)$/);
      if (holdMatch && request.method === 'DELETE') {
        return await handleCancelHold(uid, env, holdMatch[1]);
      }
      if (path === '/account' && request.method === 'GET') {
        return await handleFetchAccount(uid, env);
      }
      if (path === '/checkout-limit' && request.method === 'GET') {
        return await handleCheckoutLimit(uid, env);
      }
      const itemMatch = path.match(/^\/items\/(\d+)$/);
      if (itemMatch && request.method === 'GET') {
        return await handleItemLookup(env, itemMatch[1]);
      }

      return json({ error: 'Not found.' }, 404);
    } catch (err) {
      if (err instanceof HttpError) return json({ error: err.message }, err.status);
      return json({ error: `Internal error: ${err.message}` }, 500);
    }
  },
};
