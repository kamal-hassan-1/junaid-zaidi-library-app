import '../models/hold.dart';
import '../models/loan.dart';
import '../models/patron.dart';

/// Stand-in patron account used while the My Loans and My Holds screens are
/// built ahead of the backend. Consumed only by MockPatronRepository — no
/// screen imports this file, so when the real endpoints land this whole file is
/// deleted and nothing above the repository layer notices. Same arrangement as
/// `mock_catalog_data.dart`.
///
/// The data is shaped to exercise every UI state on purpose: a loan due weeks
/// out, one due today, one already overdue, and a hold at each of the three
/// stages. Titles are drawn from the mock catalog and keep their real ids, so a
/// loan and the catalog record it points at agree with each other.

/// Relative to now, so "due in 2 days" stays true tomorrow and the screens
/// never look stale during review.
DateTime _dueInDays(int days) => DateTime.now().add(Duration(days: days));

const _circulationDesk = 'Circulation Desk - Floor 1';
const _reserveDesk = 'Reserve Desk - Floor 1';

const Patron mockPatron = Patron(
  name: 'Ayesha Siddiqui',
  barcode: 'FA22-BCS-041',
  email: 'fa22-bcs-041@cuiisb.edu.pk',
  homeLibrary: 'Junaid Zaidi Library - Islamabad Campus',
);

/// Soonest due first, which is the order the interface promises.
final List<Loan> mockLoans = [
  Loan(
    id: 'loan-1',
    biblioId: '6',
    title: 'Computer Networks',
    author: 'Andrew S. Tanenbaum',
    dueDate: _dueInDays(-4),
  ),
  Loan(
    id: 'loan-2',
    biblioId: '8',
    title: 'The Pragmatic Programmer: Your Journey to Mastery',
    author: 'Andrew Hunt',
    dueDate: _dueInDays(0),
  ),
  Loan(
    id: 'loan-3',
    biblioId: '1',
    title: 'Introduction to Algorithms',
    author: 'Thomas H. Cormen',
    dueDate: _dueInDays(2),
  ),
  Loan(
    id: 'loan-4',
    biblioId: '5',
    title: 'Operating System Concepts',
    author: 'Abraham Silberschatz',
    dueDate: _dueInDays(12),
  ),
  Loan(
    id: 'loan-5',
    biblioId: '10',
    title: 'Signals and Systems',
    author: 'Alan V. Oppenheim',
    dueDate: _dueInDays(19),
  ),
];

/// One hold per status, so each badge and the null queue position are all
/// reachable on screen.
final List<Hold> mockHolds = [
  const Hold(
    id: 'hold-1',
    biblioId: '3',
    title: 'Design Patterns: Elements of Reusable Object-Oriented Software',
    author: 'Erich Gamma',
    queuePosition: null,
    pickupLibrary: _reserveDesk,
    status: HoldStatus.readyForPickup,
  ),
  const Hold(
    id: 'hold-2',
    biblioId: '4',
    title: 'Artificial Intelligence: A Modern Approach',
    author: 'Stuart Russell',
    queuePosition: 1,
    pickupLibrary: _circulationDesk,
    status: HoldStatus.inTransit,
  ),
  const Hold(
    id: 'hold-3',
    biblioId: '2',
    title: 'Clean Code: A Handbook of Agile Software Craftsmanship',
    author: 'Robert C. Martin',
    queuePosition: 3,
    pickupLibrary: _circulationDesk,
    status: HoldStatus.waiting,
  ),
];
