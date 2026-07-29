import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_models.dart';
import '../models/routine_source.dart';
import '../config/supabase_config.dart';
import 'cache_service.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final CacheService _cache = CacheService.instance;

  String get _userId => _client.auth.currentUser?.id ?? '';


  Future<List<Course>> getCourses() async {
    const key = 'courses';

    final cached = _cache.getList(AppConstants.coursesBox, key);
    final cachedList = cached?.map((m) => Course.fromMap(m)).toList() ?? [];

    try {
      final data = await _client
          .from(AppConstants.coursesTable)
          .select()
          .eq('user_id', _userId)
          .order('name');
      final fresh = (data as List).map((m) => Course.fromMap(m)).toList();
      await _cache.saveList(AppConstants.coursesBox, key, data.cast<Map<String, dynamic>>());
      return fresh;
    } catch (_) {
      return cachedList;
    }
  }

  Future<void> addCourse(Course course) async {
    await _client.from(AppConstants.coursesTable).insert(course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    await _client.from(AppConstants.coursesTable).delete().eq('id', id);
  }

  Future<List<ClassSlot>> getRoutine() async {
    const key = 'routine';
    final cached = _cache.getList(AppConstants.coursesBox, key);
    final cachedList = cached?.map((m) => ClassSlot.fromMap(m)).toList() ?? [];

    try {
      final data = await _client
          .from(AppConstants.classSlotTable)
          .select()
          .eq('user_id', _userId)
          .order('start_time');
      final fresh = (data as List).map((m) => ClassSlot.fromMap(m)).toList();
      await _cache.saveList(AppConstants.coursesBox, key, data.cast<Map<String, dynamic>>());
      return fresh;
    } catch (_) {
      return cachedList;
    }
  }

  Future<List<ClassSlot>> getRoutineForDay(String day) async {
    final all = await getRoutine();
    return all.where((s) => s.dayOfWeek == day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }


  Future<void> addClassSlot(ClassSlot slot) async {

    _addSlotToCache(slot);


    try {
      await _client.from(AppConstants.classSlotTable).insert(slot.toMap());
    } catch (_) {
      await _cache.addToOutbox(slot.id, 'add_class_slot', slot.toMap());
    }
  }

  Future<void> deleteClassSlot(String id) async {

    _removeSlotFromCache(id);


    try {
      await _client.from(AppConstants.classSlotTable).delete().eq('id', id);
    } catch (_) {
      await _cache.addToOutbox('del_$id', 'delete_class_slot', {'id': id});
    }
  }


  void _addSlotToCache(ClassSlot slot) {
    const key = 'routine';
    final current = _cache.getList(AppConstants.coursesBox, key) ?? [];

    current.removeWhere((m) => m['id'] == slot.id);
    current.add(slot.toMap());
    _cache.saveList(AppConstants.coursesBox, key, current);
  }

  void _removeSlotFromCache(String id) {
    const key = 'routine';
    final current = _cache.getList(AppConstants.coursesBox, key) ?? [];
    current.removeWhere((m) => m['id'] == id);
    _cache.saveList(AppConstants.coursesBox, key, current);
  }


  Future<List<RoutineSource>> getRoutineSources({bool activeOnly = true}) async {
    const key = 'routine_sources';
    final cached = _cache.getList(AppConstants.coursesBox, key)
        ?.map((m) => RoutineSource.fromMap(m))
        .toList();
    try {
      final data = await _client
          .from(AppConstants.routineSourcesTable)
          .select()
          .order('department');
      final list = (data as List).map((m) => RoutineSource.fromMap(m)).toList();
      await _cache.saveList(
          AppConstants.coursesBox, key, data.cast<Map<String, dynamic>>());
      return activeOnly ? list.where((s) => s.active).toList() : list;
    } catch (_) {
      final c = cached ?? [];
      return activeOnly ? c.where((s) => s.active).toList() : c;
    }
  }

  Future<void> addRoutineSource(RoutineSource s) async {
    await _client.from(AppConstants.routineSourcesTable).insert(s.toMap());
  }

  Future<void> updateRoutineSource(RoutineSource s) async {
    await _client
        .from(AppConstants.routineSourcesTable)
        .update(s.toMap())
        .eq('id', s.id);
  }

  Future<void> deleteRoutineSource(String id) async {
    await _client.from(AppConstants.routineSourcesTable).delete().eq('id', id);
  }


  Future<void> updateRoutinePrefs({String? department, String? batch, String? section}) async {
    await _client.from(AppConstants.profilesTable).update({
      if (department != null) 'department': department,
      'batch': batch,
      'section': section,
    }).eq('id', _userId);
  }


  Future<void> replaceImportedRoutine(List<ClassSlot> slots) async {
    await _client
        .from(AppConstants.classSlotTable)
        .delete()
        .eq('user_id', _userId)
        .eq('source', 'import');
    if (slots.isNotEmpty) {
      await _client
          .from(AppConstants.classSlotTable)
          .insert(slots.map((s) => s.toMap()).toList());
    }
    const key = 'routine';
    final current = _cache.getList(AppConstants.coursesBox, key) ?? [];
    current.removeWhere((m) => (m['source'] ?? 'manual') == 'import');
    current.addAll(slots.map((s) => s.toMap()));
    await _cache.saveList(AppConstants.coursesBox, key, current);
  }


  Future<List<Assignment>> getAssignments() async {
    const key = 'assignments';
    final cached = _cache.getList(AppConstants.assignmentsBox, key);
    final cachedList = cached?.map((m) => Assignment.fromMap(m)).toList() ?? [];

    try {
      final data = await _client
          .from(AppConstants.assignmentsTable)
          .select()
          .eq('user_id', _userId)
          .order('due_date');
      final fresh = (data as List).map((m) => Assignment.fromMap(m)).toList();
      await _cache.saveList(AppConstants.assignmentsBox, key, data.cast<Map<String, dynamic>>());
      return fresh;
    } catch (_) {
      return cachedList;
    }
  }

  Future<void> addAssignment(Assignment assignment) async {

    _addAssignmentToCache(assignment);
    try {
      await _client.from(AppConstants.assignmentsTable).insert(assignment.toMap());
    } catch (_) {
      await _cache.addToOutbox(assignment.id, 'add_assignment', assignment.toMap());
    }
  }

  void _addAssignmentToCache(Assignment a) {
    const key = 'assignments';
    final current = _cache.getList(AppConstants.assignmentsBox, key) ?? [];
    current.removeWhere((m) => m['id'] == a.id);
    current.add(a.toMap());
    _cache.saveList(AppConstants.assignmentsBox, key, current);
  }

  Future<void> updateAssignment(Assignment assignment) async {
    try {
      await _client
          .from(AppConstants.assignmentsTable)
          .update({'status': assignment.status, 'progress_percent': assignment.progressPercent})
          .eq('id', assignment.id);
    } catch (_) {
      // Queue for offline sync
      await _cache.addToOutbox(
        assignment.id,
        'update_assignment',
        {'id': assignment.id, 'status': assignment.status, 'progress_percent': assignment.progressPercent},
      );
    }
  }

  /// Edits the saved (editable) fields of a task: title, notes, course,
  /// due date and type. Status/progress are left untouched (use
  /// [updateAssignment] for those). Updates the local cache first so the
  /// change shows immediately and works offline.
  Future<void> editAssignment(Assignment assignment) async {

    _addAssignmentToCache(assignment);
    final payload = {
      'id': assignment.id,
      'title': assignment.title,
      'description': assignment.description,
      'course_name': assignment.courseName,
      'due_date': assignment.dueDate.toIso8601String(),
      'task_type': assignment.type,
    };
    try {
      await _client
          .from(AppConstants.assignmentsTable)
          .update({
        'title': payload['title'],
        'description': payload['description'],
        'course_name': payload['course_name'],
        'due_date': payload['due_date'],
        'task_type': payload['task_type'],
      })
          .eq('id', assignment.id);
    } catch (_) {
      await _cache.addToOutbox(assignment.id, 'edit_assignment', payload);
    }
  }

  Future<void> deleteAssignment(String id) async {
    await _client.from(AppConstants.assignmentsTable).delete().eq('id', id);
  }


  Future<List<AttendanceRecord>> getAttendance() async {
    const key = 'attendance';
    final cached = _cache.getList(AppConstants.attendanceBox, key);
    final cachedList = cached?.map((m) => AttendanceRecord.fromMap(m)).toList() ?? [];

    try {
      final data = await _client
          .from(AppConstants.attendanceTable)
          .select()
          .eq('user_id', _userId)
          .order('date', ascending: false);
      final fresh = (data as List).map((m) => AttendanceRecord.fromMap(m)).toList();
      await _cache.saveList(AppConstants.attendanceBox, key, data.cast<Map<String, dynamic>>());
      return fresh;
    } catch (_) {
      return cachedList;
    }
  }

  Future<List<AttendanceSummary>> getAttendanceSummary() async {
    final records = await getAttendance();
    final courses = await getCourses();
    final Map<String, List<AttendanceRecord>> byCourse = {};

    for (final r in records) {
      byCourse.putIfAbsent(r.courseId, () => []).add(r);
    }

    return courses.map((c) {
      final courseRecords = byCourse[c.id] ?? [];
      return AttendanceSummary(
        courseId: c.id,
        courseName: c.name,
        totalClasses: courseRecords.length,
        attendedClasses: courseRecords.where((r) => r.present).length,
      );
    }).toList();
  }

  Future<void> addAttendance(AttendanceRecord record) async {
    try {
      await _client.from(AppConstants.attendanceTable).upsert(record.toMap());
    } catch (_) {
      await _cache.addToOutbox(record.id, 'add_attendance', record.toMap());
    }
  }


  Future<List<Grade>> getGrades({String? semester}) async {
    try {
      var query = _client
          .from(AppConstants.gradesTable)
          .select()
          .eq('user_id', _userId);
      if (semester != null) query = query.eq('semester', semester);
      final data = await query.order('course_name');
      return (data as List).map((m) => Grade.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<double> calculateCGPA() async {
    final grades = await getGrades();
    if (grades.isEmpty) return 0.0;
    double totalPoints = 0;
    int totalCredits = 0;
    for (final g in grades) {
      if (g.gradePoints != null) {
        totalPoints += g.gradePoints! * g.creditHours;
        totalCredits += g.creditHours;
      }
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  Future<void> upsertGrade(Grade grade) async {
    await _client.from(AppConstants.gradesTable).upsert(grade.toMap());
  }

  Future<void> deleteGrade(String id) async {
    await _client.from(AppConstants.gradesTable).delete().eq('id', id);
  }

  // Number of changes waiting to sync (size of the offline outbox).
  int pendingSyncCount() => _cache.getOutbox().length;


  Future<List<Notice>> getNotices() async {
    const key = 'notices';
    final cached = _cache.getList(AppConstants.noticesBox, key);
    final cachedList = cached?.map((m) => Notice.fromMap(m)).toList() ?? [];

    try {
      final data = await _client
          .from(AppConstants.noticesTable)
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      final fresh = (data as List).map((m) => Notice.fromMap(m)).toList();
      await _cache.saveList(AppConstants.noticesBox, key, data.cast<Map<String, dynamic>>());
      return fresh;
    } catch (_) {
      return cachedList;
    }
  }

  Future<void> addNotice(Notice notice) async {
    await _client.from(AppConstants.noticesTable).insert(notice.toMap());
  }


  Future<List<ChatMessage>> getMessages(String roomId, {int limit = 50}) async {
    try {
      final data = await _client
          .from(AppConstants.messagesTable)
          .select()
          .eq('room_id', roomId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (data as List).map((m) => ChatMessage.fromMap(m)).toList().reversed.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> sendMessage(ChatMessage message) async {
    await _client.from(AppConstants.messagesTable).insert(message.toMap());
  }

  // Realtime subscription for chat
  RealtimeChannel subscribeToMessages(String roomId, Function(ChatMessage) onMessage) {
    return _client
        .channel('messages:$roomId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.messagesTable,
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
      callback: (payload) {
        final msg = ChatMessage.fromMap(payload.newRecord);
        onMessage(msg);
      },
    )
        .subscribe();
  }


  Future<bool> drainOutbox() async {
    final pending = _cache.getOutbox();
    if (pending.isEmpty) return false;
    var synced = false;
    for (final action in pending) {
      try {
        switch (action['type']) {
          case 'update_assignment':
            await _client
                .from(AppConstants.assignmentsTable)
                .update({'status': action['payload']['status'], 'progress_percent': action['payload']['progress_percent']})
                .eq('id', action['payload']['id']);
            break;
          case 'edit_assignment':
            await _client
                .from(AppConstants.assignmentsTable)
                .update({
              'title': action['payload']['title'],
              'description': action['payload']['description'],
              'course_name': action['payload']['course_name'],
              'due_date': action['payload']['due_date'],
              'task_type': action['payload']['task_type'],
            })
                .eq('id', action['payload']['id']);
            break;
          case 'add_attendance':
            await _client.from(AppConstants.attendanceTable).upsert(action['payload']);
            break;
          case 'add_assignment':
            await _client.from(AppConstants.assignmentsTable).insert(action['payload']);
            break;
          case 'add_class_slot':
            await _client.from(AppConstants.classSlotTable).insert(action['payload']);
            break;
          case 'delete_class_slot':
            await _client.from(AppConstants.classSlotTable).delete().eq('id', action['payload']['id']);
            break;
        }
        await _cache.removeFromOutbox(action['id']);
        synced = true;
      } catch (_) {

      }
    }
    return synced;
  }
}