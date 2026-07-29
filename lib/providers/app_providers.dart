import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import '../config/supabase_config.dart';
import '../models/app_models.dart';
import '../models/routine_source.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final dbServiceProvider   = Provider<DatabaseService>((ref) => DatabaseService());
final aiServiceProvider   = Provider<AiService>((ref) => AiService());


class ThemeModeNotifier extends StateNotifier<ThemeMode> {

  static const _box = AppConstants.userBox;
  static const _key = 'theme_mode';

  ThemeModeNotifier() : super(_load());

  static ThemeMode _load() {
    final saved = CacheService.instance.get<String>(_box, _key, (d) => d as String);
    switch (saved) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  void _persist(ThemeMode mode) {

    CacheService.instance.save(_box, _key, mode.name);
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _persist(state);
  }

  void set(ThemeMode mode) {
    state = mode;
    _persist(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
      (ref) => ThemeModeNotifier(),
);


final isOnlineProvider = StateProvider<bool>((ref) => true);


final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(dbServiceProvider).pendingSyncCount();
});


final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final auth = ref.watch(authServiceProvider);
  return auth.getCurrentProfile();
});


final coursesProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(dbServiceProvider).getCourses();
});


final selectedDayProvider = StateProvider<String>((ref) {

  const byWeekday = {
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
  };
  return byWeekday[DateTime.now().weekday] ?? 'Saturday';
});

final routineProvider = FutureProvider<List<ClassSlot>>((ref) async {
  return ref.watch(dbServiceProvider).getRoutine();
});

final dayRoutineProvider = FutureProvider<List<ClassSlot>>((ref) async {
  final day = ref.watch(selectedDayProvider);
  return ref.watch(dbServiceProvider).getRoutineForDay(day);
});


final routineSourcesProvider = FutureProvider<List<RoutineSource>>((ref) async {
  return ref.watch(dbServiceProvider).getRoutineSources();
});

final allRoutineSourcesProvider = FutureProvider<List<RoutineSource>>((ref) async {
  return ref.watch(dbServiceProvider).getRoutineSources(activeOnly: false);
});


final assignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  return ref.watch(dbServiceProvider).getAssignments();
});

final pendingAssignmentsProvider = FutureProvider<List<Assignment>>((ref) async {
  final all = await ref.watch(assignmentsProvider.future);
  return all.where((a) => a.status != 'done').toList();
});


final attendanceSummaryProvider = FutureProvider<List<AttendanceSummary>>((ref) async {
  return ref.watch(dbServiceProvider).getAttendanceSummary();
});

final overallAttendanceProvider = FutureProvider<double>((ref) async {
  final summaries = await ref.watch(attendanceSummaryProvider.future);
  if (summaries.isEmpty) return 0.0;
  final total    = summaries.fold<int>(0, (s, a) => s + a.totalClasses);
  final attended = summaries.fold<int>(0, (s, a) => s + a.attendedClasses);
  return total == 0 ? 0.0 : attended / total;
});


final cgpaProvider = FutureProvider<double>((ref) async {
  return ref.watch(dbServiceProvider).calculateCGPA();
});

final gradesProvider = FutureProvider.family<List<Grade>, String?>((ref, semester) async {
  return ref.watch(dbServiceProvider).getGrades(semester: semester);
});


final noticesProvider = FutureProvider<List<Notice>>((ref) async {
  return ref.watch(dbServiceProvider).getNotices();
});


final selectedRoomProvider = StateProvider<String>((ref) => 'general');

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>((ref, channel) async {
  return ref.watch(dbServiceProvider).getMessages(channel);
});


class AiChatNotifier extends StateNotifier<List<Map<String, String>>> {
  AiChatNotifier() : super([]);
  void add(String role, String content) => state = [...state, {'role': role, 'content': content}];
  void clear() => state = [];
}

final aiChatProvider = StateNotifierProvider<AiChatNotifier, List<Map<String, String>>>(
      (ref) => AiChatNotifier(),
);