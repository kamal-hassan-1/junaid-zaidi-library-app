class ProfileData {
  final String fullName;
  final String registrationNumber;
  final String? department;
  final String? email;
  final String? phone;
  final String? cnic;
  final bool isLimited;

  const ProfileData({
    required this.fullName,
    required this.registrationNumber,
    this.department,
    this.email,
    this.phone,
    this.cnic,
    this.isLimited = false,
  });
}