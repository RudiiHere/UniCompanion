import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/app_models.dart';

class RoutineImportException implements Exception {
  final String message;
  RoutineImportException(this.message);
  @override
  String toString() => message;
}

class RoutineImportService {

  static const List<String> days = [
    'Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
  ];


  static const List<String> batches = [
    '71', '70', '69', '68', '67', '66', '65', '64', '63', '62', '61', '60',
  ];
  static const List<String> sections = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
  ];

  final _uuid = const Uuid();

  /// Fetches and parses the routine for [batch] + [section] from [sheetId].
  /// Returns class slots tagged source = 'import'. Throws
  /// [RoutineImportException] if the sheet can't be reached.
  Future<List<ClassSlot>> fetchRoutine({
    required String sheetId,
    required String batch,
    required String section,
    required String userId,
  }) async {
    final wantBatch = batch.trim();
    final wantSection = section.trim().toUpperCase();
    final all = <ClassSlot>[];
    var reachedAny = false;

    for (final day in days) {
      try {
        final body = await _fetchCsv(sheetId, day);
        if (body.trimLeft().startsWith('<')) continue; // login/HTML, not CSV
        reachedAny = true;
        all.addAll(_parseDay(body, day, wantBatch, wantSection, userId));
      } catch (_) {
        // Skip a day we couldn't load; keep trying the rest.
      }
    }

    if (!reachedAny) {
      throw RoutineImportException(
        'Could not load the routine sheet. Make sure it is shared as '
            '"Anyone with the link can view".',
      );
    }
    return all;
  }

  Future<String> _fetchCsv(String sheetId, String dayTab) async {
    // Google's CSV export endpoint for a sheet, selected by tab name.
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq'
          '?tqx=out:csv&sheet=${Uri.encodeComponent(dayTab)}',
    );
    final res = await http.get(url).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw RoutineImportException('HTTP ${res.statusCode} for $dayTab');
    }
    return res.body;
  }

  // -- Parsing ---------------------------------------------------------------
  List<ClassSlot> _parseDay(
      String csv, String day, String batch, String section, String userId,
      ) {
    final rows = _parseCsv(csv);
    if (rows.isEmpty) return [];

    final timeRe = RegExp(r'(\d{1,2}):(\d{2})\s*[-–—]\s*(\d{1,2}):(\d{2})');

    int headerRow = -1, batchCol = -1, sectionCol = -1;
    final timeCols = <int, List<String>>{}; // colIndex -> [start24, end24]
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r].map((e) => e.trim()).toList();
      final bi = row.indexWhere((c) => c.toLowerCase() == 'batch');
      final si = row.indexWhere((c) => c.toLowerCase() == 'section');
      if (bi != -1 && si != -1) {
        headerRow = r;
        batchCol = bi;
        sectionCol = si;
        for (var c = 0; c < row.length; c++) {
          final m = timeRe.firstMatch(row[c]);
          if (m != null) {
            timeCols[c] = [
              _to24(m.group(1)!, m.group(2)!),
              _to24(m.group(3)!, m.group(4)!),
            ];
          }
        }
        break;
      }
    }
    if (headerRow == -1 || timeCols.isEmpty) return [];

    final orderedCols = timeCols.keys.toList()..sort();
    final slots = <ClassSlot>[];

    for (var r = headerRow + 1; r < rows.length; r++) {
      final row = rows[r].map((e) => e.trim()).toList();
      if (batchCol >= row.length || sectionCol >= row.length) continue;
      if (row[batchCol] != batch) continue;

      final sec = row[sectionCol].toUpperCase();
      final secMatch = sec == section ||
          sec.split('+').map((e) => e.trim()).contains(section);
      if (!secMatch) continue;

      String? prevRaw;
      var prevPos = -2;
      for (var i = 0; i < orderedCols.length; i++) {
        final col = orderedCols[i];
        final raw = col < row.length ? row[col].trim() : '';
        if (raw.isEmpty || raw.toUpperCase() == 'BREAK') {
          prevRaw = null;
          continue;
        }
        final end = timeCols[col]![1];
        if (raw == prevRaw && i == prevPos + 1 && slots.isNotEmpty) {
          final last = slots.removeLast();
          slots.add(_copyWithEnd(last, end));
        } else {
          slots.add(_makeSlot(raw, day, timeCols[col]![0], end, userId));
        }
        prevRaw = raw;
        prevPos = i;
      }
    }
    return slots;
  }

  // Minimal RFC-4180-style CSV parser: handles quoted fields, escaped quotes
  // (""), commas and newlines inside quotes. Returns rows of string cells.
  List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;

    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          endField();
        } else if (c == '\n') {
          endRow();
        } else if (c == '\r') {
          if (!(i + 1 < input.length && input[i + 1] == '\n')) endRow();
        } else {
          field.write(c);
        }
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }

  ClassSlot _makeSlot(String raw, String day, String start, String end, String userId) {
    final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final codeRe = RegExp(r'^[A-Z]{2,5}-?\d{3,4}[A-Z]?$', caseSensitive: false);
    final teacherRe = RegExp(r'^[A-Za-z]{2,4}$');

    String code = raw, teacher = '', room = '';
    if (parts.isNotEmpty && codeRe.hasMatch(parts[0])) {
      code = parts[0];
      if (parts.length >= 2 && teacherRe.hasMatch(parts[1])) {
        teacher = parts[1].toUpperCase();
        room = parts.sublist(2).join(' ');
      } else {
        room = parts.sublist(1).join(' ');
      }
    }
    return ClassSlot(
      id: _uuid.v4(),
      courseId: _uuid.v4(),
      courseName: code,
      courseCode: teacher,
      dayOfWeek: day,
      startTime: start,
      endTime: end,
      room: room.isEmpty ? null : room,
      userId: userId,
      source: 'import', // so re-sync only replaces these
    );
  }

  ClassSlot _copyWithEnd(ClassSlot s, String end) => ClassSlot(
    id: s.id,
    courseId: s.courseId,
    courseName: s.courseName,
    courseCode: s.courseCode,
    dayOfWeek: s.dayOfWeek,
    startTime: s.startTime,
    endTime: end,
    room: s.room,
    userId: s.userId,
    source: s.source,
  );

  String _to24(String h, String m) {
    var hh = int.parse(h);
    if (hh >= 1 && hh <= 8) hh += 12; // 1-8 = afternoon
    return '${hh.toString().padLeft(2, '0')}:$m';
  }
}