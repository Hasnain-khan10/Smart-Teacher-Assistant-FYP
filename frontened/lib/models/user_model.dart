class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;

  // 🔹 Common Fields
  final String? fatherName;
  final String? cnic;
  final String? department;

  // 👨‍🎓 Student Specific
  final String? rollNumber;
  final String? semester;
  final String? section;

  // 👨‍🏫 Teacher Specific
  final String? qualification;
  final String? experience;
  final String? speciality;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
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
      id: json['_id'] ?? json['id'] ?? "",
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      role: json['role'] ?? "student",
      profileImage: json["profileImage"],
      fatherName: json['fatherName'],
      cnic: json['cnic'],
      department: json['department'],
      rollNumber: json['rollNumber'],
      semester: json['semester'],
      section: json['section'],
      qualification: json['qualification'],
      experience: json['experience']?.toString(), // Int/String dono ko handle karne ke liye
      speciality: json['speciality'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "role": role,
      "profileImage": profileImage,
      "fatherName": fatherName,
      "cnic": cnic,
      "department": department,
      "rollNumber": rollNumber,
      "semester": semester,
      "section": section,
      "qualification": qualification,
      "experience": experience,
      "speciality": speciality,
    };
  }
}