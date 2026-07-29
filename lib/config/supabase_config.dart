class SupabaseConfig {

  static const String supabaseUrl = 'https://mhzhshgiqofjjrxwcozi.supabase.co';


  static const String supabaseAnonKey = 'sb_publishable_yr9iDCkROFEheJUT8bI9Fg_3gIyz3Ad';
}

class AppConstants {
  static const String appName = 'UniCompanion';
  static const String appVersion = '1.0.0';


  static const String profilesTable = 'profiles';
  static const String coursesTable = 'courses';
  static const String classSlotTable = 'class_slots';
  static const String assignmentsTable = 'assignments';
  static const String attendanceTable = 'attendance';
  static const String gradesTable = 'grades';
  static const String noticesTable = 'notices';
  static const String messagesTable = 'messages';
  static const String chatRoomsTable = 'chat_rooms';
  static const String routineSourcesTable = 'routine_sources';


  static const String userBox = 'user_box';
  static const String coursesBox = 'courses_box';
  static const String assignmentsBox = 'assignments_box';
  static const String noticesBox = 'notices_box';
  static const String attendanceBox = 'attendance_box';
  static const String outboxBox = 'outbox_box';


  static const String sessionKey = 'supabase_session';


  static const double attendanceWarningThreshold = 0.78;
  static const double attendanceMinThreshold = 0.75;
}