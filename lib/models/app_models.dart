class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? studentId;
  final String? department;
  final int? semester;
  final String? batch;
  final String? section;
  final String role; // 'student' | 'admin'
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.studentId,
    this.department,
    this.semester,
    this.batch,
    this.section,
    this.role = 'student',
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    id: map['id'] ?? '',
    email: map['email'] ?? '',
    fullName: map['full_name'] ?? '',
    avatarUrl: map['avatar_url'],
    studentId: map['student_id'],
    department: map['department'],
    semester: map['semester'],
    batch: map['batch'],
    section: map['section'],
    role: map['role'] ?? 'student',
    createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
    'student_id': studentId,
    'department': department,
    'semester': semester,
    'batch': batch,
    'section': section,
    'role': role,
    'created_at': createdAt.toIso8601String(),
  };
}

class Course {
  final String id;
  final String name;
  final String code;
  final String? teacherName;
  final int creditHours;
  final String userId;

  Course({
    required this.id,
    required this.name,
    required this.code,
    this.teacherName,
    this.creditHours = 3,
    required this.userId,
  });

  factory Course.fromMap(Map<String, dynamic> map) => Course(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    code: map['code'] ?? '',
    teacherName: map['teacher_name'],
    creditHours: map['credit_hours'] ?? 3,
    userId: map['user_id'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'code': code,
    'teacher_name': teacherName,
    'credit_hours': creditHours,
    'user_id': userId,
  };
}

class ClassSlot {
  final String id;
  final String courseId;
  final String courseName;
  final String courseCode;
  final String dayOfWeek; // 'Monday', 'Tuesday', etc.
  final String startTime; // '09:00'
  final String endTime;   // '10:30'
  final String? room;
  final String userId;
  final String source; // 'manual' (default) or 'import'

  ClassSlot({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.room,
    required this.userId,
    this.source = 'manual',
  });

  factory ClassSlot.fromMap(Map<String, dynamic> map) => ClassSlot(
    id: map['id'] ?? '',
    courseId: map['course_id'] ?? '',
    courseName: map['course_name'] ?? '',
    courseCode: map['course_code'] ?? '',
    dayOfWeek: map['day_of_week'] ?? '',
    startTime: map['start_time'] ?? '',
    endTime: map['end_time'] ?? '',
    room: map['room'],
    userId: map['user_id'] ?? '',
    source: map['source'] ?? 'manual',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'course_id': courseId,
    'course_name': courseName,
    'course_code': courseCode,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    'room': room,
    'user_id': userId,
    'source': source,
  };
}

class Assignment {
  final String id;
  final String title;
  final String? description;
  final String courseId;
  final String courseName;
  final DateTime dueDate;
  final String status; // 'pending' | 'done' | 'overdue'
  final int progressPercent;
  final String type; // 'assignment' | 'lab' | 'class_test' | 'presentation' | 'viva'
  final String userId;
  final DateTime createdAt;

  Assignment({
    required this.id,
    required this.title,
    this.description,
    required this.courseId,
    required this.courseName,
    required this.dueDate,
    this.status = 'pending',
    this.progressPercent = 0,
    this.type = 'assignment',
    required this.userId,
    required this.createdAt,
  });

  bool get isOverdue =>
      dueDate.isBefore(DateTime.now()) && status != 'done';

  int get daysUntilDue =>
      dueDate.difference(DateTime.now()).inDays;

  factory Assignment.fromMap(Map<String, dynamic> map) => Assignment(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'],
    courseId: map['course_id'] ?? '',
    courseName: map['course_name'] ?? '',
    dueDate: DateTime.parse(map['due_date']),
    status: map['status'] ?? 'pending',
    progressPercent: map['progress_percent'] ?? 0,
    type: map['task_type'] ?? 'assignment',
    userId: map['user_id'] ?? '',
    createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'course_id': courseId,
    'course_name': courseName,
    'due_date': dueDate.toIso8601String(),
    'status': status,
    'progress_percent': progressPercent,
    'task_type': type,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
  };

  Assignment copyWith({String? status, int? progressPercent, String? type}) => Assignment(
    id: id,
    title: title,
    description: description,
    courseId: courseId,
    courseName: courseName,
    dueDate: dueDate,
    status: status ?? this.status,
    progressPercent: progressPercent ?? this.progressPercent,
    type: type ?? this.type,
    userId: userId,
    createdAt: createdAt,
  );
}

class AttendanceRecord {
  final String id;
  final String courseId;
  final String courseName;
  final String userId;
  final DateTime date;
  final bool present;

  AttendanceRecord({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.userId,
    required this.date,
    required this.present,
  });

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) => AttendanceRecord(
    id: map['id'] ?? '',
    courseId: map['course_id'] ?? '',
    courseName: map['course_name'] ?? '',
    userId: map['user_id'] ?? '',
    date: DateTime.parse(map['date']),
    present: map['present'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'course_id': courseId,
    'course_name': courseName,
    'user_id': userId,
    'date': date.toIso8601String(),
    'present': present,
  };
}

class AttendanceSummary {
  final String courseId;
  final String courseName;
  final int totalClasses;
  final int attendedClasses;

  AttendanceSummary({
    required this.courseId,
    required this.courseName,
    required this.totalClasses,
    required this.attendedClasses,
  });

  double get percentage =>
      totalClasses == 0 ? 0 : attendedClasses / totalClasses;

  bool get isAtRisk => percentage < 0.78 && percentage >= 0.75;
  bool get isBelowMinimum => percentage < 0.75;
}

class Grade {
  final String id;
  final String courseId;
  final String courseName;
  final int creditHours;
  final String? letterGrade; // 'A', 'A-', 'B+', etc.
  final double? gradePoints;
  final String userId;
  final String semester;

  Grade({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.creditHours,
    this.letterGrade,
    this.gradePoints,
    required this.userId,
    required this.semester,
  });

  factory Grade.fromMap(Map<String, dynamic> map) => Grade(
    id: map['id'] ?? '',
    courseId: map['course_id'] ?? '',
    courseName: map['course_name'] ?? '',
    creditHours: map['credit_hours'] ?? 3,
    letterGrade: map['letter_grade'],
    gradePoints: (map['grade_points'] as num?)?.toDouble(),
    userId: map['user_id'] ?? '',
    semester: map['semester'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'course_id': courseId,
    'course_name': courseName,
    'credit_hours': creditHours,
    'letter_grade': letterGrade,
    'grade_points': gradePoints,
    'user_id': userId,
    'semester': semester,
  };

  static double letterToPoints(String letter) {
    const map = {
      'A+': 4.0, 'A': 4.0, 'A-': 3.7, 'B+': 3.3, 'B': 3.0,
      'B-': 2.7, 'C+': 2.3, 'C': 2.0, 'C-': 1.7,
      'D+': 1.3, 'D': 1.0, 'F': 0.0,
    };
    return map[letter] ?? 0.0;
  }
}

class Notice {
  final String id;
  final String title;
  final String content;
  final String category; // 'academic' | 'event' | 'update' | 'general'
  final String postedBy;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.postedBy,
    required this.createdAt,
  });

  factory Notice.fromMap(Map<String, dynamic> map) => Notice(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    category: map['category'] ?? 'general',
    postedBy: map['posted_by'] ?? '',
    createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'posted_by': postedBy,
    'created_at': createdAt.toIso8601String(),
  };
}

class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'] ?? '',
    roomId: map['room_id'] ?? '',
    userId: map['user_id'] ?? '',
    userName: map['user_name'] ?? '',
    content: map['content'] ?? '',
    createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'room_id': roomId,
    'user_id': userId,
    'user_name': userName,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };
}

class OutboxAction {
  final String id;
  final String type; // 'update_assignment', 'mark_attendance', etc.
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  OutboxAction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });
}