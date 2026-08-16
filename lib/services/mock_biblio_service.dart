import '../models/biblio.dart';
import 'biblio_service.dart';

/// Canned catalog data standing in for a real Koha instance (see
/// [ApiConstants.useMockKohaBackend]). Filtering happens here rather than in
/// OpacScreen so the screen's code path is identical to the real
/// [BiblioService] — swapping the two is a one-line change.
class MockBiblioService implements BiblioSource {
  /// Simulated network latency so loading/search spinners have something
  /// real to show during development.
  static const _simulatedLatency = Duration(milliseconds: 450);

  static final List<Biblio> _catalog = [
    const Biblio(
      biblioId: 1,
      title: 'Introduction to Algorithms',
      author: 'Cormen, Thomas H.',
      isbn: '9780262046305',
      publisher: 'MIT Press',
      publicationYear: '2022',
      itemType: 'BK',
      pages: '1312',
      homeLibraryId: 'isb',
      subjects: ['Algorithms', 'Computer Science'],
    ),
    const Biblio(
      biblioId: 2,
      title: 'Database System Concepts',
      author: 'Silberschatz, Abraham',
      isbn: '9780078022159',
      publisher: 'McGraw-Hill',
      publicationYear: '2019',
      itemType: 'BK',
      pages: '1376',
      homeLibraryId: 'isb',
      subjects: ['Database', 'Computer Science'],
    ),
    const Biblio(
      biblioId: 3,
      title: 'Computer Networks',
      author: 'Tanenbaum, Andrew S.',
      isbn: '9780132126953',
      publisher: 'Pearson',
      publicationYear: '2021',
      itemType: 'BK',
      pages: '960',
      homeLibraryId: 'lhr',
      subjects: ['Computer Networks', 'Computer Science'],
    ),
    const Biblio(
      biblioId: 4,
      title: 'Operating System Concepts',
      author: 'Silberschatz, Abraham',
      isbn: '9781119800361',
      publisher: 'Wiley',
      publicationYear: '2021',
      itemType: 'BK',
      pages: '720',
      homeLibraryId: 'isb',
      subjects: ['Operating Systems', 'Computer Science'],
    ),
    const Biblio(
      biblioId: 5,
      title: 'Clean Code: A Handbook of Agile Software Craftsmanship',
      author: 'Martin, Robert C.',
      isbn: '9780132350884',
      publisher: 'Prentice Hall',
      publicationYear: '2008',
      itemType: 'BK',
      pages: '464',
      homeLibraryId: 'isb',
      subjects: ['Software Engineering', 'Programming'],
    ),
    const Biblio(
      biblioId: 6,
      title: 'Artificial Intelligence: A Modern Approach',
      author: 'Russell, Stuart',
      isbn: '9780134610993',
      publisher: 'Pearson',
      publicationYear: '2020',
      itemType: 'BK',
      pages: '1136',
      homeLibraryId: 'isb',
      subjects: ['Artificial Intelligence', 'Computer Science'],
    ),
    const Biblio(
      biblioId: 7,
      title: 'Digital Design and Computer Architecture',
      author: 'Harris, David Money',
      isbn: '9780128200643',
      publisher: 'Morgan Kaufmann',
      publicationYear: '2021',
      itemType: 'BK',
      pages: '698',
      homeLibraryId: 'atk',
      subjects: ['Computer Architecture', 'Electronics'],
    ),
    const Biblio(
      biblioId: 8,
      title: 'IEEE Transactions on Software Engineering',
      author: null,
      issn: '0098-5589',
      publisher: 'IEEE',
      publicationYear: '2025',
      itemType: 'CR',
      serial: true,
      homeLibraryId: 'isb',
      subjects: ['Software Engineering'],
    ),
    const Biblio(
      biblioId: 9,
      title: 'Software Engineering: A Practitioner\'s Approach',
      author: 'Pressman, Roger S.',
      isbn: '9781259872976',
      publisher: 'McGraw-Hill',
      publicationYear: '2019',
      itemType: 'BK',
      pages: '976',
      homeLibraryId: 'lhr',
      subjects: ['Software Engineering'],
    ),
    const Biblio(
      biblioId: 10,
      title: 'COMSATS Journal of Emerging Sciences',
      author: null,
      issn: '1023-4144',
      publisher: 'COMSATS University Islamabad',
      publicationYear: '2025',
      itemType: 'CR',
      serial: true,
      homeLibraryId: 'isb',
      subjects: ['Science', 'Research'],
    ),
    const Biblio(
      biblioId: 11,
      title: 'Discrete Mathematics and Its Applications',
      author: 'Rosen, Kenneth H.',
      isbn: '9781259676512',
      publisher: 'McGraw-Hill',
      publicationYear: '2019',
      itemType: 'BK',
      pages: '1071',
      homeLibraryId: 'isb',
      subjects: ['Mathematics', 'Discrete Mathematics'],
    ),
    const Biblio(
      biblioId: 12,
      title: 'Linear Algebra and Its Applications',
      author: 'Lay, David C.',
      isbn: '9780321982384',
      publisher: 'Pearson',
      publicationYear: '2016',
      itemType: 'BK',
      pages: '576',
      homeLibraryId: 'swl',
      subjects: ['Mathematics', 'Linear Algebra'],
    ),
    const Biblio(
      biblioId: 13,
      title: 'The Pragmatic Programmer',
      author: 'Hunt, Andrew',
      isbn: '9780135957059',
      publisher: 'Addison-Wesley',
      publicationYear: '2019',
      itemType: 'BK',
      pages: '352',
      homeLibraryId: 'isb',
      subjects: ['Software Engineering', 'Programming'],
    ),
    const Biblio(
      biblioId: 14,
      title: 'Campus Map of COMSATS University Islamabad',
      author: null,
      publisher: 'COMSATS University Islamabad',
      publicationYear: '2024',
      itemType: 'MP',
      homeLibraryId: 'isb',
      subjects: ['Maps'],
    ),
    const Biblio(
      biblioId: 15,
      title: 'Deep Learning',
      author: 'Goodfellow, Ian',
      isbn: '9780262035613',
      publisher: 'MIT Press',
      publicationYear: '2016',
      itemType: 'EBK',
      pages: '800',
      homeLibraryId: 'isb',
      subjects: ['Machine Learning', 'Artificial Intelligence'],
    ),
    const Biblio(
      biblioId: 16,
      title: 'Computer Networks: An Open Source Approach',
      author: 'Liu, Jean-Yves',
      isbn: '9780073376896',
      publisher: 'McGraw-Hill',
      publicationYear: '2018',
      itemType: 'EBK',
      pages: '840',
      homeLibraryId: 'veh',
      subjects: ['Computer Networks'],
    ),
    const Biblio(
      biblioId: 17,
      title: 'A Comparative Study of Load Balancing Algorithms in Cloud Computing',
      author: 'Ahmed, Bilal',
      publisher: 'COMSATS University Islamabad',
      publicationYear: '2023',
      itemType: 'THESIS',
      pages: '112',
      homeLibraryId: 'isb',
      subjects: ['Cloud Computing', 'Load Balancing'],
    ),
    const Biblio(
      biblioId: 18,
      title: 'Machine Learning Approaches for Intrusion Detection in IoT Networks',
      author: 'Fatima, Sana',
      publisher: 'COMSATS University Islamabad',
      publicationYear: '2024',
      itemType: 'THESIS',
      pages: '98',
      homeLibraryId: 'isb',
      subjects: ['Machine Learning', 'IoT', 'Network Security'],
    ),
    const Biblio(
      biblioId: 19,
      title: 'MATLAB & Simulink Student Suite',
      author: null,
      isbn: '9780136800880',
      publisher: 'MathWorks',
      publicationYear: '2023',
      itemType: 'CF',
      homeLibraryId: 'wah',
      subjects: ['MATLAB', 'Simulation'],
    ),
    const Biblio(
      biblioId: 20,
      title: 'Embedded Systems: Introduction to ARM Cortex-M Microcontrollers',
      author: 'Valvano, Jonathan W.',
      isbn: '9781477508992',
      publisher: 'Jonathan Valvano',
      publicationYear: '2020',
      itemType: 'BK',
      pages: '560',
      homeLibraryId: 'atd',
      subjects: ['Embedded Systems', 'Electronics'],
    ),
  ];

  @override
  Future<List<Biblio>> fetchAll() async {
    await Future.delayed(_simulatedLatency);
    return List.unmodifiable(_catalog);
  }

  @override
  Future<Biblio?> fetchOne(int biblioId) async {
    await Future.delayed(_simulatedLatency);
    for (final b in _catalog) {
      if (b.biblioId == biblioId) return b;
    }
    return null;
  }

  @override
  Future<List<Biblio>> search(
    String query, {
    String? itemType,
    String? searchField,
    String? campus,
  }) async {
    await Future.delayed(_simulatedLatency);
    final trimmed = query.trim().toLowerCase();

    return _catalog.where((b) {
      if (itemType != null && b.itemType != itemType) return false;
      if (campus != null && b.homeLibraryId != campus) return false;
      if (trimmed.isEmpty) return true;

      switch (searchField) {
        case 'ti':
          return b.title.toLowerCase().contains(trimmed);
        case 'au':
          return (b.author ?? '').toLowerCase().contains(trimmed);
        case 'su':
          return b.subjects.any((s) => s.toLowerCase().contains(trimmed));
        case 'nb':
          return (b.isbn ?? '').toLowerCase().contains(trimmed);
        case 'ns':
          return (b.issn ?? '').toLowerCase().contains(trimmed);
        default:
          // Keyword: match any of title/author/subjects/ISBN/ISSN.
          return b.title.toLowerCase().contains(trimmed) ||
              (b.author ?? '').toLowerCase().contains(trimmed) ||
              b.subjects.any((s) => s.toLowerCase().contains(trimmed)) ||
              (b.isbn ?? '').toLowerCase().contains(trimmed) ||
              (b.issn ?? '').toLowerCase().contains(trimmed);
      }
    }).toList();
  }
}
