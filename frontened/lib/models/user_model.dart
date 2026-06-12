class UserModel {
  final String id;
  final String name;
  final String? profileImage;
  final String email;
  final String role;

  // 🔹 Common
  final String? fatherName;
  final String? cnic;
  final String? department;

  // 👨‍🎓 Student
  final String? rollNumber;
  final String? semester;
  final String? section;

  // 👨‍🏫 Teacher
  final String? qualification;
  final String? experience;
  final String? speciality;

  UserModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.email,
    required this.role,

    this.fatherName,
    this.cnic,
    this.department,

    this.rollNumber,
    this.semester,
    this.section,

    this.qualification,
    this.experience,
    this.speciality,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? "",
      name: json['name'] ?? "",
      profileImage:
      json["profileImage"] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? '',

      fatherName: json['fatherName'],
      cnic: json['cnic'],
      department: json['department'],

      rollNumber: json['rollNumber'],
      semester: json['semester'],
      section: json['section'],

      qualification: json['qualification'],
      experience: json['experience'],
      speciality: json['speciality'],
    );
  }
}