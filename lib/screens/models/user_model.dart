class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String patronymic;
  final String department;
  final String role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.patronymic,
    required this.department,
    required this.role,
  });

  String get fullName => '$lastName $firstName $patronymic';

  factory UserModel.fromDocument(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      patronymic: data['patronymic'] ?? '',
      department: data['department'] ?? '',
      role: data['role'] ?? '',
    );
  }
}
