/// ROTATED 2026-08-18 — a repo audit found this file's credentials had
/// been sitting in this PUBLIC GitHub repo, readable by anyone. Changing
/// [validatorPassword] here does NOTHING by itself: this account's
/// actual password must also be changed on every real Koha instance that
/// currently has it set to the old value ('Api@1234'), or the leaked
/// credential keeps working regardless of what this file says. This
/// account has staff-level Koha access used directly by the app (see
/// BiblioService/CirculationService) — until it's rotated server-side
/// too, treat the old value as still live and exploitable.
class KohaServiceAccount {
  const KohaServiceAccount._();
  static const String validatorUserid = 'apiuser';
  static const String validatorPassword = '7U%f%UYxvUjD_f!WD-xa0xHxEz&D';
}