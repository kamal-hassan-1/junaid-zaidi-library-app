import '../../data/mock_patron_data.dart';
import '../../models/hold.dart';
import '../../models/loan.dart';
import '../../models/patron.dart';
import '../patron_repository.dart';

/// Answers every patron call from `mock_patron_data.dart`, so My Loans and My
/// Holds can be built and reviewed before the backend exists.
///
/// Shaped like `MockCatalogRepository`: fixtures behind the interface, an
/// artificial delay so loading states are visible, and lists handed out
/// unmodifiable so a screen cannot quietly mutate the fixtures and leave the
/// next screen looking at edited data.
///
/// Unlike the catalog mock there is no failure trigger. The catalog had one
/// because a student can type `error` into a search box; nothing here takes
/// input, so the error states are exercised by tests injecting their own
/// repository instead.
class MockPatronRepository implements PatronRepository {
  /// Simulated network delay, so loading states are actually visible while the
  /// UI is being reviewed. Tests pass [Duration.zero].
  final Duration latency;

  MockPatronRepository({this.latency = const Duration(milliseconds: 700)});

  @override
  Future<Patron> getPatron() async {
    await Future<void>.delayed(latency);
    return mockPatron;
  }

  @override
  Future<List<Loan>> getLoans() async {
    await Future<void>.delayed(latency);
    return List<Loan>.unmodifiable(mockLoans);
  }

  @override
  Future<List<Hold>> getHolds() async {
    await Future<void>.delayed(latency);
    return List<Hold>.unmodifiable(mockHolds);
  }
}
