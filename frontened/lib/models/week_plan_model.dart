class WeekModel {
  final int weekNumber;
  final String title;

  final List<String> topics;
  final List<String> clo;
  final List<String> objectives;
  final List<String> tasks;

  /// 🧠 AI ANALYTICS
  final String advantages;
  final String disadvantages;

  WeekModel({
    required this.weekNumber,
    required this.title,
    required this.topics,
    required this.clo,
    required this.objectives,
    required this.tasks,
    required this.advantages,
    required this.disadvantages,
  });

  factory WeekModel.fromJson(Map<String, dynamic> json) {
    return WeekModel(
      weekNumber: (json['weekNumber'] ?? 0) is int
          ? json['weekNumber']
          : int.tryParse(json['weekNumber'].toString()) ?? 0,

      title: json['title']?.toString() ?? '',

      topics: (json['topics'] is List)
          ? List<String>.from(json['topics'])
          : [],

      clo: (json['clo'] is List)
          ? List<String>.from(json['clo'])
          : json['clo'] != null
          ? [json['clo'].toString()]
          : [],

      objectives: (json['objectives'] is List)
          ? List<String>.from(json['objectives'])
          : [],

      tasks: (json['tasks'] is List)
          ? List<String>.from(json['tasks'])
          : [],

      advantages: json['advantages']?.toString() ?? '',
      disadvantages: json['disadvantages']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "weekNumber": weekNumber,
      "title": title,
      "topics": topics,
      "clo": clo,
      "objectives": objectives,
      "tasks": tasks,
      "advantages": advantages,
      "disadvantages": disadvantages,
    };
  }
}


class WeekPlanModel {
  final String id;

  /// COURSE INFO
  final String courseId;
  final String courseTitle;
  final String courseCode;

  /// PLAN INFO
  final String title;
  final String description;

  /// 🧠 AI INPUT
  final String? prompt;
  final String generationSource; // prompt | book | both

  /// 📘 BOOK DATA
  final String? bookFileUrl;
  final String? bookFileType;
  final String? bookExtractedText;

  /// CORE
  final List<WeekModel> weeks;
  final int semesterDuration;

  final String? pdfUrl;

  WeekPlanModel({
    required this.id,
    required this.courseId,
    required this.courseTitle,
    required this.courseCode,
    required this.title,
    required this.description,
    required this.weeks,
    required this.semesterDuration,

    this.pdfUrl,
    this.prompt,

    required this.generationSource,
    this.bookFileUrl,
    this.bookFileType,
    this.bookExtractedText,
  });

  factory WeekPlanModel.fromJson(Map<String, dynamic> json) {
    final course = json['course'];

    String courseId = '';
    String courseTitle = '';
    String courseCode = '';

    if (course is Map<String, dynamic>) {
      courseId = course['_id']?.toString() ?? '';
      courseTitle = course['title']?.toString() ?? '';
      courseCode = course['courseCode']?.toString() ?? '';
    }

    return WeekPlanModel(
      id: json['_id']?.toString() ?? '',

      courseId: courseId,
      courseTitle: courseTitle,
      courseCode: courseCode,

      title: json['title']?.toString() ?? 'AI Generated 18 Week Plan',
      description: json['description']?.toString() ?? '',

      prompt: json['prompt']?.toString(),

      /// ✅ NEW
      generationSource:
      json['generationSource']?.toString() ?? 'prompt',

      bookFileUrl: json['bookFileUrl']?.toString(),
      bookFileType: json['bookFileType']?.toString(),
      bookExtractedText:
      json['bookExtractedText']?.toString(),

      weeks: (json['weeks'] is List)
          ? (json['weeks'] as List)
          .map((e) => WeekModel.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .toList()
          : [],

      semesterDuration: (json['semesterDuration'] ?? 18) is int
          ? json['semesterDuration']
          : int.tryParse(json['semesterDuration'].toString()) ?? 18,

      pdfUrl: json['pdfUrl']?.toString(),
    );
  }
}