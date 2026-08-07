/// Static placeholder — no auth/session yet, so this is fixed sample data.
class Student {
  final String name;
  final String registrationNumber;
  final String department;
  final String email;

  const Student({
    required this.name,
    required this.registrationNumber,
    required this.department,
    required this.email,
  });
}

const Student student = Student(
  name: 'Student Name',
  registrationNumber: 'FA00-BCS-000',
  department: 'Department of Computer Science',
  email: 'student@cuiisb.edu.pk',
);
