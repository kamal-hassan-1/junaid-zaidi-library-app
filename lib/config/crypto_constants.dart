/// Shared-secret AES key used to encrypt a student's password
/// client-side before it's ever written to Firestore (Updated
/// Authentication Workflow, Phase 1 / Step 2).
///
/// ---- Why this changed from RSA to AES ----
/// The previous version used RSA (a public/private keypair): the app
/// only had the PUBLIC key, and only a Cloud Function — running on a
/// server, holding the PRIVATE key in a hidden environment variable —
/// could ever decrypt. That's genuinely stronger, but it requires a
/// server, and a server requires Firebase's paid Blaze plan.
///
/// Without a server, there is nowhere to hide a private key at all —
/// admin-dashboard.html, running in a browser, is the thing doing the
/// decrypting now, and it's a plain HTML file anyone can open and read
/// the source of. So this is now a SINGLE shared secret instead: the
/// same string encrypts (in the app) and decrypts (in
/// admin-dashboard.html). Both sides must have the EXACT same value.
///
/// ---- What this does and doesn't protect against ----
/// This still stops someone casually browsing Firestore's console/data
/// exports from reading a student's plaintext password. It does NOT
/// stop someone who decompiles the app or reads admin-dashboard.html's
/// source from recovering this secret — at that point they'd have the
/// same decryption ability the dashboard has. That's an inherent
/// limit of "no backend, no billing card" — not a bug, just a
/// real tradeoff you already agreed to. Keep admin-dashboard.html off
/// the public internet / undiscoverable, since that page's login
/// (checked against the `admins` Firestore collection) is the actual
/// access gate — this secret is a second layer on top of that, not a
/// replacement for it.
///
/// ROTATED 2026-08-18: a repo audit found the previous value had been
/// sitting in this file (and admin-dashboard.html) in a PUBLIC GitHub
/// repo — anyone could read it and decrypt any pending student's real
/// password. Treat the old value as permanently burned even though it's
/// gone from HEAD now — it's still in git history, which is exactly why
/// a leaked secret must be rotated, not just deleted. Generated with
/// `openssl rand -hex 32`.
///
/// TODO: this repo is PUBLIC. Every value committed here is visible to
/// anyone, forever (git history survives even after a file changes).
/// A real fix needs this secret to stop living in a public repo at all —
/// e.g. build-time injection from a private source — not just a fresh
/// rotation. Rotating buys time, it doesn't close the actual hole.
/// Update this file AND admin-dashboard.html's PENDING_PASSWORD_SECRET
/// together — they must always match exactly.
class CryptoConstants {
  const CryptoConstants._();

  static const String passwordEncryptionSharedSecret =
      '00f1b123b98241b2be5053057ef2b124af243758892e4ddb718d6019009b76a8';
}