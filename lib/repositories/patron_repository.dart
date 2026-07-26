import '../models/hold.dart';
import '../models/loan.dart';
import '../models/patron.dart';

/// Thrown when a patron request fails.
///
/// Callers show [message] directly — it is already written to be user-facing,
/// matching `CatalogException` and `SessionException`.
///
/// There is no `PatronNotFoundException` counterpart to
/// `CatalogNotFoundException`. Every method here is about *the* signed-in
/// patron, so "no such patron" is not a thing the student typed wrong — it is a
/// broken session, and the auth flow's problem rather than a state for these
/// screens to render.
class PatronException implements Exception {
  final String message;

  const PatronException(this.message);

  @override
  String toString() => message;
}

/// The signed-in student's own library account.
///
/// Read-only for now. Renewing, placing and cancelling holds are all deliberate
/// omissions: they are writes, they need endpoints that do not exist, and the
/// UI ships their buttons disabled.
///
/// No method takes a patron id. Which patron this is follows from the session
/// (`SessionRepository`), so passing one in would let a caller ask for somebody
/// else's loans — an authorization decision that belongs on the server.
///
/// Every method is async even though the mock answers synchronously, for the
/// reason `CatalogRepository` gives: swapping in the REST implementation should
/// change no call site.
///
/// Endpoints are **TBD**. The API contract documents nothing for the patron
/// account yet, so unlike `CatalogRepository` this interface names no paths
/// rather than guessing at them.
abstract interface class PatronRepository {
  /// The patron record behind the current session.
  ///
  /// Throws [PatronException] if the request fails.
  Future<Patron> getPatron();

  /// Items currently checked out, soonest due first.
  ///
  /// An empty list is a normal answer — a student with nothing out — not an
  /// error. Throws [PatronException] if the request fails.
  Future<List<Loan>> getLoans();

  /// Outstanding reservations, in queue order.
  ///
  /// Empty is likewise normal. Throws [PatronException] if the request fails.
  Future<List<Hold>> getHolds();
}
