class RoutineSource {
  final String id;
  final String department;
  final String sheetId;
  final String? label;
  final bool active;

  RoutineSource({
    required this.id,
    required this.department,
    required this.sheetId,
    this.label,
    this.active = true,
  });

  String get title =>
      (label != null && label!.trim().isNotEmpty) ? label! : department;

  factory RoutineSource.fromMap(Map<String, dynamic> m) => RoutineSource(
    id: m['id'] ?? '',
    department: m['department'] ?? '',
    sheetId: m['sheet_id'] ?? '',
    label: m['label'],
    active: m['active'] ?? true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'department': department,
    'sheet_id': sheetId,
    'label': label,
    'active': active,
  };

  RoutineSource copyWith({
    String? department,
    String? sheetId,
    String? label,
    bool? active,
  }) =>
      RoutineSource(
        id: id,
        department: department ?? this.department,
        sheetId: sheetId ?? this.sheetId,
        label: label ?? this.label,
        active: active ?? this.active,
      );

  /// Accepts a full Google Sheets URL or a bare ID and returns just the ID.
  static String extractSheetId(String input) {
    final s = input.trim();
    final m = RegExp(r'/spreadsheets/d/([A-Za-z0-9_-]+)').firstMatch(s);
    return m != null ? m.group(1)! : s;
  }
}