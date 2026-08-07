/// COMSATS University Islamabad's campuses, shown as the Campus dropdown
/// during registration. Student, Staff, and Teacher signup all read from
/// this same list â€” kept as flat display strings rather than an enum
/// since nothing else in the app currently branches on which campus was
/// picked. It's stored on the request/user document purely for the
/// admin dashboard's benefit right now.
const List<String> kComsatsCampuses = [
  'Islamabad',
  'Abbottabad',
  'Attock',
  'Lahore',
  'Sahiwal',
  'Vehari',
  'Wah',
  'Virtual Campus',
];
