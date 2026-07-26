import '../models/catalog_holding.dart';
import '../models/catalog_item.dart';

/// Stand-in catalog used while the OPAC UI is built ahead of the backend.
/// Consumed only by MockCatalogRepository — no screen imports this file, so
/// when GET /api/v1/juno/search goes live this whole file is deleted and
/// nothing above the repository layer notices.
///
/// The data is shaped to exercise every UI state on purpose: titles that
/// are too long for one line, missing publication years, records with no
/// copies at all, and titles where every copy is checked out.

DateTime _dueInDays(int days) => DateTime.now().add(Duration(days: days));

CatalogHolding _copy(
  String itemId,
  String library,
  String callNumber,
  ItemAvailability availability, {
  int? dueInDays,
}) {
  return CatalogHolding(
    itemId: itemId,
    library: library,
    callNumber: callNumber,
    availability: availability,
    dueDate: dueInDays == null ? null : _dueInDays(dueInDays),
  );
}

const _stacks = 'Main Stacks - Floor 2';
const _reference = 'Reference Section - Floor 1';
const _reserve = 'Reserve Desk - Floor 1';

final Map<String, List<CatalogHolding>> mockCatalogHoldings = {
  '1': [
    _copy('1-a', _stacks, '005.1 COR', ItemAvailability.available),
    _copy('1-b', _stacks, '005.1 COR', ItemAvailability.checkedOut, dueInDays: 6),
    _copy('1-c', _reserve, '005.1 COR', ItemAvailability.reference),
  ],
  '2': [
    _copy('2-a', _stacks, '005.1 MAR', ItemAvailability.checkedOut, dueInDays: 3),
    _copy('2-b', _stacks, '005.1 MAR', ItemAvailability.checkedOut, dueInDays: 11),
  ],
  '3': [
    _copy('3-a', _stacks, '005.12 GAM', ItemAvailability.available),
  ],
  '4': [
    _copy('4-a', _stacks, '006.3 RUS', ItemAvailability.available),
    _copy('4-b', _stacks, '006.3 RUS', ItemAvailability.available),
    _copy('4-c', _stacks, '006.3 RUS', ItemAvailability.checkedOut, dueInDays: 2),
  ],
  '5': [
    _copy('5-a', _stacks, '005.43 SIL', ItemAvailability.available),
    _copy('5-b', _stacks, '005.43 SIL', ItemAvailability.unavailable),
  ],
  '6': [
    _copy('6-a', _stacks, '004.6 TAN', ItemAvailability.available),
    _copy('6-b', _stacks, '004.6 TAN', ItemAvailability.checkedOut, dueInDays: 9),
  ],
  '7': [
    _copy('7-a', _stacks, '005.74 SIL', ItemAvailability.available),
  ],
  '8': [
    _copy('8-a', _stacks, '005.1 HUN', ItemAvailability.available),
    _copy('8-b', _reserve, '005.1 HUN', ItemAvailability.reference),
  ],
  '9': [
    _copy('9-a', _stacks, '621.395 MAN', ItemAvailability.available),
    _copy('9-b', _stacks, '621.395 MAN', ItemAvailability.available),
  ],
  '10': [
    _copy('10-a', _stacks, '621.382 OPP', ItemAvailability.checkedOut, dueInDays: 14),
    _copy('10-b', _stacks, '621.382 OPP', ItemAvailability.available),
  ],
  '11': [
    _copy('11-a', _stacks, '621.381 SED', ItemAvailability.available),
    _copy('11-b', _stacks, '621.381 SED', ItemAvailability.checkedOut, dueInDays: 5),
    _copy('11-c', _stacks, '621.381 SED', ItemAvailability.available),
  ],
  '12': [
    _copy('12-a', _stacks, '537 HAY', ItemAvailability.available),
  ],
  '13': [
    _copy('13-a', _stacks, '515 STE', ItemAvailability.checkedOut, dueInDays: 1),
    _copy('13-b', _stacks, '515 STE', ItemAvailability.checkedOut, dueInDays: 8),
    _copy('13-c', _stacks, '515 STE', ItemAvailability.checkedOut, dueInDays: 20),
  ],
  '14': [
    _copy('14-a', _stacks, '512.5 LAY', ItemAvailability.available),
    _copy('14-b', _stacks, '512.5 LAY', ItemAvailability.available),
  ],
  '15': [
    _copy('15-a', _stacks, '511.1 ROS', ItemAvailability.available),
    _copy('15-b', _reserve, '511.1 ROS', ItemAvailability.reference),
  ],
  '16': [
    _copy('16-a', _stacks, '519.2 WAL', ItemAvailability.available),
    _copy('16-b', _reference, '519.2 WAL', ItemAvailability.reference),
  ],
  '17': [
    _copy('17-a', _stacks, '530 HAL', ItemAvailability.available),
    _copy('17-b', _stacks, '530 HAL', ItemAvailability.checkedOut, dueInDays: 4),
  ],
  '18': [
    _copy('18-a', _stacks, '658 KOO', ItemAvailability.available),
  ],
  '19': [
    _copy('19-a', _stacks, '658.8 KOT', ItemAvailability.available),
    _copy('19-b', _stacks, '658.8 KOT', ItemAvailability.checkedOut, dueInDays: 7),
  ],
  '20': [
    _copy('20-a', _stacks, '657 WEY', ItemAvailability.available),
  ],
  '21': [
    _copy('21-a', _stacks, '005.1 SOM', ItemAvailability.available),
    _copy('21-b', _stacks, '005.1 SOM', ItemAvailability.available),
    _copy('21-c', _reserve, '005.1 SOM', ItemAvailability.reference),
  ],
  '22': [
    _copy('22-a', _stacks, '004.22 PAT', ItemAvailability.available),
  ],
  // Deliberately absent from this map: record 23 has no copies at all
  // (on order), which is a real Koha state and exercises the "No copies"
  // badge plus an empty holdings section on the detail screen.
  '24': [
    _copy('24-a', _stacks, '006.31 GOO', ItemAvailability.checkedOut, dueInDays: 12),
  ],
  '25': [
    _copy('25-a', _stacks, '005.8 STA', ItemAvailability.available),
    _copy('25-b', _stacks, '005.8 STA', ItemAvailability.unavailable),
  ],
};

/// Builds a record with availability counts derived from its holdings, so
/// the badge on a search result can never contradict the copy list on the
/// detail screen.
CatalogItem _item({
  required String id,
  required String title,
  String? author,
  String? publisher,
  int? year,
  String? isbn,
  String itemType = 'Books',
  String? summary,
  List<String> subjects = const [],
}) {
  final holdings = mockCatalogHoldings[id] ?? const <CatalogHolding>[];
  return CatalogItem(
    id: id,
    title: title,
    author: author,
    publisher: publisher,
    year: year,
    isbn: isbn,
    itemType: itemType,
    summary: summary,
    language: 'English',
    subjects: subjects,
    availableCount:
        holdings.where((h) => h.availability == ItemAvailability.available).length,
    totalCount: holdings.length,
  );
}

final List<CatalogItem> mockCatalogItems = [
  _item(
    id: '1',
    title: 'Introduction to Algorithms',
    author: 'Thomas H. Cormen',
    publisher: 'MIT Press',
    year: 2009,
    isbn: '9780262033848',
    summary:
        'A comprehensive treatment of algorithm design and analysis, covering sorting, '
        'graph algorithms, dynamic programming and NP-completeness.',
    subjects: ['Computer algorithms', 'Data structures'],
  ),
  _item(
    id: '2',
    title: 'Clean Code: A Handbook of Agile Software Craftsmanship',
    author: 'Robert C. Martin',
    publisher: 'Prentice Hall',
    year: 2008,
    isbn: '9780132350884',
    summary:
        'Principles and practices for writing readable, maintainable code, illustrated '
        'through case studies in refactoring.',
    subjects: ['Software engineering', 'Computer programming'],
  ),
  _item(
    id: '3',
    title: 'Design Patterns: Elements of Reusable Object-Oriented Software',
    author: 'Erich Gamma',
    publisher: 'Addison-Wesley',
    year: 1994,
    isbn: '9780201633610',
    summary:
        'Catalogues twenty-three classic object-oriented design patterns with worked '
        'examples and guidance on when each applies.',
    subjects: ['Object-oriented programming', 'Software architecture'],
  ),
  _item(
    id: '4',
    title: 'Artificial Intelligence: A Modern Approach',
    author: 'Stuart Russell',
    publisher: 'Pearson',
    year: 2020,
    isbn: '9780134610993',
    summary:
        'The standard survey of artificial intelligence, spanning search, knowledge '
        'representation, probabilistic reasoning, learning and robotics.',
    subjects: ['Artificial intelligence', 'Machine learning'],
  ),
  _item(
    id: '5',
    title: 'Operating System Concepts',
    author: 'Abraham Silberschatz',
    publisher: 'Wiley',
    year: 2018,
    isbn: '9781119456339',
    summary:
        'Covers processes, threads, scheduling, memory management, storage and '
        'protection in modern operating systems.',
    subjects: ['Operating systems', 'Computer science'],
  ),
  _item(
    id: '6',
    title: 'Computer Networks',
    author: 'Andrew S. Tanenbaum',
    publisher: 'Pearson',
    year: 2010,
    isbn: '9780132126953',
    summary:
        'A layered introduction to networking, from the physical layer through to '
        'application protocols and network security.',
    subjects: ['Computer networks', 'Data transmission'],
  ),
  _item(
    id: '7',
    title: 'Database System Concepts',
    author: 'Abraham Silberschatz',
    publisher: 'McGraw-Hill',
    year: 2019,
    isbn: '9780078022159',
    summary:
        'Relational modelling, SQL, transaction management, indexing and distributed '
        'database design.',
    subjects: ['Database management', 'SQL'],
  ),
  _item(
    id: '8',
    title: 'The Pragmatic Programmer: Your Journey to Mastery',
    author: 'Andrew Hunt',
    publisher: 'Addison-Wesley',
    year: 2019,
    isbn: '9780135957059',
    summary:
        'Practical advice on craftsmanship, tooling, debugging and career development '
        'for working software developers.',
    subjects: ['Computer programming', 'Software engineering'],
  ),
  _item(
    id: '9',
    title: 'Digital Design: With an Introduction to the Verilog HDL',
    author: 'M. Morris Mano',
    publisher: 'Pearson',
    year: 2017,
    isbn: '9780134549897',
    summary:
        'Boolean algebra, combinational and sequential logic, and register transfer '
        'design using Verilog.',
    subjects: ['Digital electronics', 'Logic design'],
  ),
  _item(
    id: '10',
    title: 'Signals and Systems',
    author: 'Alan V. Oppenheim',
    publisher: 'Pearson',
    year: 1996,
    isbn: '9780138147570',
    summary:
        'Continuous and discrete-time signal analysis, Fourier and Laplace transforms, '
        'and linear time-invariant system behaviour.',
    subjects: ['Signal processing', 'System analysis'],
  ),
  _item(
    id: '11',
    title: 'Microelectronic Circuits',
    author: 'Adel S. Sedra',
    publisher: 'Oxford University Press',
    year: 2014,
    isbn: '9780199339136',
    summary:
        'Device physics through to amplifier and digital circuit design, with SPICE '
        'simulation examples.',
    subjects: ['Electronic circuits', 'Semiconductors'],
  ),
  _item(
    id: '12',
    title: 'Engineering Electromagnetics',
    author: 'William H. Hayt',
    publisher: 'McGraw-Hill',
    year: 2018,
    isbn: '9780078028151',
    summary:
        'Vector analysis, electrostatics, magnetostatics, Maxwell\'s equations and '
        'transmission line theory.',
    subjects: ['Electromagnetism', 'Electrical engineering'],
  ),
  _item(
    id: '13',
    title: 'Calculus: Early Transcendentals',
    author: 'James Stewart',
    publisher: 'Cengage Learning',
    year: 2015,
    isbn: '9781285741550',
    summary:
        'Single and multivariable calculus with an emphasis on conceptual understanding '
        'and applied problem solving.',
    subjects: ['Calculus', 'Mathematics'],
  ),
  _item(
    id: '14',
    title: 'Linear Algebra and Its Applications',
    author: 'David C. Lay',
    publisher: 'Pearson',
    year: 2015,
    isbn: '9780321982384',
    summary:
        'Vector spaces, eigenvalues, orthogonality and least squares, with applications '
        'to computer graphics and data analysis.',
    subjects: ['Linear algebra', 'Mathematics'],
  ),
  _item(
    id: '15',
    title: 'Discrete Mathematics and Its Applications',
    author: 'Kenneth H. Rosen',
    publisher: 'McGraw-Hill',
    year: 2018,
    isbn: '9781259676512',
    summary:
        'Logic, proof techniques, combinatorics, graph theory and recurrence relations '
        'for computer science students.',
    subjects: ['Discrete mathematics', 'Graph theory'],
  ),
  _item(
    id: '16',
    title: 'Probability and Statistics for Engineers and Scientists',
    author: 'Ronald E. Walpole',
    publisher: 'Pearson',
    year: 2016,
    isbn: '9780134115856',
    summary:
        'Probability distributions, estimation, hypothesis testing and regression, with '
        'engineering worked examples.',
    subjects: ['Probability', 'Statistics'],
  ),
  _item(
    id: '17',
    title: 'Fundamentals of Physics',
    author: 'David Halliday',
    publisher: 'Wiley',
    year: 2013,
    isbn: '9781118230718',
    summary:
        'Mechanics, thermodynamics, electromagnetism, optics and modern physics for '
        'first-year undergraduates.',
    subjects: ['Physics', 'Mechanics'],
  ),
  _item(
    id: '18',
    title: 'Essentials of Management',
    author: 'Harold Koontz',
    publisher: 'McGraw-Hill',
    year: 2012,
    isbn: '9781259027925',
    summary:
        'An international perspective on planning, organizing, staffing, leading and '
        'controlling within organizations.',
    subjects: ['Management', 'Business administration'],
  ),
  _item(
    id: '19',
    title: 'Marketing Management',
    author: 'Philip Kotler',
    publisher: 'Pearson',
    year: 2015,
    isbn: '9780133856460',
    summary:
        'Market analysis, segmentation, brand strategy and the marketing mix, supported '
        'by contemporary case studies.',
    subjects: ['Marketing', 'Management'],
  ),
  _item(
    id: '20',
    title: 'Financial Accounting',
    author: 'Jerry J. Weygandt',
    publisher: 'Wiley',
    year: 2019,
    isbn: '9781119594611',
    summary:
        'The accounting cycle, financial statement preparation and analysis under '
        'international reporting standards.',
    subjects: ['Accounting', 'Finance'],
  ),
  _item(
    id: '21',
    title: 'Software Engineering',
    author: 'Ian Sommerville',
    publisher: 'Pearson',
    year: 2015,
    isbn: '9780133943030',
    summary:
        'Requirements engineering, architectural design, testing and project management '
        'across the software lifecycle.',
    subjects: ['Software engineering', 'Project management'],
  ),
  _item(
    id: '22',
    title: 'Computer Organization and Design: The Hardware/Software Interface',
    author: 'David A. Patterson',
    publisher: 'Morgan Kaufmann',
    year: 2020,
    isbn: '9780128201091',
    summary:
        'Instruction set architecture, pipelining, memory hierarchy and parallelism, '
        'taught through the RISC-V instruction set.',
    subjects: ['Computer architecture', 'Digital systems'],
  ),
  _item(
    id: '23',
    title: 'Machine Learning',
    author: 'Tom M. Mitchell',
    publisher: 'McGraw-Hill',
    year: 1997,
    isbn: '9780070428072',
    summary:
        'Foundational treatment of concept learning, decision trees, neural networks, '
        'Bayesian methods and reinforcement learning.',
    subjects: ['Machine learning', 'Artificial intelligence'],
  ),
  _item(
    id: '24',
    title: 'Deep Learning',
    author: 'Ian Goodfellow',
    publisher: 'MIT Press',
    year: 2016,
    isbn: '9780262035613',
    summary:
        'Mathematical foundations, deep feedforward and convolutional networks, '
        'sequence modelling and generative models.',
    subjects: ['Deep learning', 'Neural networks'],
  ),
  _item(
    id: '25',
    title: 'Cryptography and Network Security: Principles and Practice',
    author: 'William Stallings',
    publisher: 'Pearson',
    year: 2017,
    isbn: '9780134444284',
    summary:
        'Symmetric and public-key cryptography, authentication protocols, and network '
        'and internet security practice.',
    subjects: ['Cryptography', 'Computer security'],
  ),
];
