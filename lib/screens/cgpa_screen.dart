import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';

class CgpaScreen extends ConsumerWidget {
  const CgpaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpaAsync   = ref.watch(cgpaProvider);
    final gradesAsync = ref.watch(gradesProvider(null));
    final isOnline    = ref.watch(isOnlineProvider);
    final pending     = ref.watch(pendingSyncCountProvider).maybeWhen(data: (n) => n, orElse: () => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CGPA Calculator'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openGradeSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isOnline || pending > 0) _offlineBanner(context, isOnline, pending),

          // ── CGPA hero ─────────────────────────────────────────────────
          cgpaAsync.when(
            data: (cgpa) => _heroCard(cgpa),
            loading: () => const ShimmerCard(height: 160),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 20),

          gradesAsync.when(
            data: (grades) {
              if (grades.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: EmptyState(
                    icon: Icons.grade_outlined,
                    title: 'No grades yet',
                    subtitle: 'Add your courses to calculate your CGPA',
                    action: ElevatedButton(
                      onPressed: () => _openGradeSheet(context, ref),
                      child: const Text('Add grade'),
                    ),
                  ),
                );
              }

              // Group by semester.
              final bySem = <String, List<Grade>>{};
              for (final g in grades) {
                final s = g.semester.trim().isEmpty ? 'Unspecified' : g.semester.trim();
                bySem.putIfAbsent(s, () => []).add(g);
              }
              final sems = bySem.keys.toList()
                ..sort((a, b) => _semesterSortKey(a).compareTo(_semesterSortKey(b)));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trend chart (needs at least 2 semesters to be meaningful).
                  if (sems.length >= 2) ...[
                    const SectionHeader(title: 'GPA Trend'),
                    const SizedBox(height: 12),
                    _trendChart(context, sems, bySem),
                    const SizedBox(height: 24),
                  ],
                  const SectionHeader(title: 'By Semester'),
                  const SizedBox(height: 12),
                  for (final sem in sems) _semesterSection(context, ref, sem, bySem[sem]!),
                ],
              );
            },
            loading: () => Column(
              children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 8), child: ShimmerCard(height: 70))),
            ),
            error: (_, __) => const Text('Could not load grades'),
          ),
        ],
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────
  Widget _heroCard(double cgpa) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: AppTheme.indigo.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
    ),
    child: Column(
      children: [
        const Text('Current CGPA', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(cgpa.toStringAsFixed(2),
            style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -2)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(100)),
          child: Text(_cgpaLabel(cgpa), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  // ── Trend chart ──────────────────────────────────────────────────────
  Widget _trendChart(BuildContext context, List<String> sems, Map<String, List<Grade>> bySem) {
    final cs = Theme.of(context).colorScheme;
    final spots = <FlSpot>[];
    for (var i = 0; i < sems.length; i++) {
      spots.add(FlSpot(i.toDouble(), _sgpa(bySem[sems[i]]!)));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4), width: 0.5),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (v) => FlLine(color: cs.outline.withValues(alpha: 0.25), strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, interval: 1, reservedSize: 26,
                getTitlesWidget: (v, meta) => Text(v.toInt().toString(),
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 32,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= sems.length || v != i.toDouble()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_shortSem(sems[i]),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.indigo,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppTheme.indigo.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }

  // ── One semester block ───────────────────────────────────────────────
  Widget _semesterSection(BuildContext context, WidgetRef ref, String sem, List<Grade> grades) {
    final cs = Theme.of(context).colorScheme;
    final sgpa = _sgpa(grades);
    final credits = grades.fold<int>(0, (s, g) => s + g.creditHours);
    final sgColor = _pointColor(sgpa);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Semester header
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(sem, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                ),
                Text('$credits cr', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(color: sgColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
                  child: Text('CGPA ${sgpa.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sgColor)),
                ),
              ],
            ),
          ),
          for (final g in grades) _gradeRow(context, ref, g),
        ],
      ),
    );
  }

  Widget _gradeRow(BuildContext context, WidgetRef ref, Grade g) {
    final cs = Theme.of(context).colorScheme;
    final pts = g.gradePoints ?? 0;
    final color = _pointColor(pts);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openGradeSheet(context, ref, existing: g),
        child: AppCard(
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Center(child: Text(g.letterGrade ?? '–',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.courseName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                  Text('${g.creditHours} credits · ${pts.toStringAsFixed(2)} pts',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 19, color: cs.onSurfaceVariant),
              onPressed: () => _confirmDelete(context, ref, g),
              tooltip: 'Delete',
            ),
          ]),
        ),
      ),
    );
  }

  Widget _offlineBanner(BuildContext context, bool online, int pending) {
    final cs = Theme.of(context).colorScheme;
    final offline = !online;
    final color = offline ? AppTheme.amber : cs.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(offline ? Icons.cloud_off_rounded : Icons.sync_rounded, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            offline
                ? (pending > 0 ? 'Offline · $pending change${pending == 1 ? '' : 's'} will sync later' : 'Offline · changes saved on device')
                : 'Syncing $pending change${pending == 1 ? '' : 's'}…',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Grade g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete grade?'),
        content: Text('Remove "${g.courseName}" from your CGPA?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.rose, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(dbServiceProvider).deleteGrade(g.id);
      ref.invalidate(gradesProvider);
      ref.invalidate(cgpaProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete. Check your connection and try again.')),
        );
      }
    }
  }

  void _openGradeSheet(BuildContext context, WidgetRef ref, {Grade? existing}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradeSheet(existing: existing),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  static double _sgpa(List<Grade> grades) {
    double pts = 0; int cr = 0;
    for (final g in grades) {
      if (g.gradePoints != null) { pts += g.gradePoints! * g.creditHours; cr += g.creditHours; }
    }
    return cr == 0 ? 0 : pts / cr;
  }

  static Color _pointColor(double pts) {
    if (pts >= 3.5) return AppTheme.emerald;
    if (pts >= 2.75) return AppTheme.sky;
    if (pts >= 2.0) return AppTheme.amber;
    return AppTheme.rose;
  }

  // Best-effort chronological ordering of free-text semesters
  // (e.g. "Spring 2025", "Fall 2024", "Semester 1").
  static double _semesterSortKey(String s) {
    final lower = s.toLowerCase();
    final yearMatch = RegExp(r'(\d{4})').firstMatch(s);
    final year = yearMatch != null ? double.parse(yearMatch.group(1)!) : 0;
    double term = 0;
    if (lower.contains('spring')) {
      term = 0.1;
    } else if (lower.contains('summer')) {
      term = 0.2;
    } else if (lower.contains('fall') || lower.contains('autumn')) {
      term = 0.3;
    } else if (lower.contains('winter')) {
      term = 0.4;
    } else {
      final n = RegExp(r'(\d{1,2})').firstMatch(lower.replaceAll(RegExp(r'\d{4}'), ''));
      if (n != null) term = double.parse(n.group(1)!) / 100;
    }
    return year + term;
  }

  static String _shortSem(String s) {
    final year = RegExp(r'(\d{4})').firstMatch(s)?.group(1);
    final term = s.split(' ').first;
    final t = term.length > 3 ? term.substring(0, 3) : term;
    return year != null ? '$t\n${year.substring(2)}' : (s.length > 6 ? s.substring(0, 6) : s);
  }

  static String _cgpaLabel(double cgpa) {
    if (cgpa >= 3.75) return '🏆 Outstanding';
    if (cgpa >= 3.5) return '🌟 Excellent';
    if (cgpa >= 3.0) return '✅ Very Good';
    if (cgpa >= 2.5) return '📘 Good Standing';
    if (cgpa >= 2.0) return '📗 Satisfactory';
    return '⚠️ Needs Improvement';
  }
}

// ── Add / Edit grade sheet ─────────────────────────────────────────────
class _GradeSheet extends ConsumerStatefulWidget {
  final Grade? existing;
  const _GradeSheet({this.existing});

  @override
  ConsumerState<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends ConsumerState<_GradeSheet> {
  late final TextEditingController _courseCtrl;
  late final TextEditingController _semesterCtrl;
  late int _credits;
  late String _grade;
  bool _saving = false;

  static const _grades = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'F'];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _courseCtrl = TextEditingController(text: g?.courseName ?? '');
    _semesterCtrl = TextEditingController(text: g?.semester ?? 'Spring 2025');
    _credits = g?.creditHours ?? 3;
    _grade = g?.letterGrade ?? 'A+';
  }

  @override
  void dispose() {
    _courseCtrl.dispose();
    _semesterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 18),
          Text(_isEdit ? 'Edit Grade' : 'Add Grade', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          TextFormField(controller: _courseCtrl, textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Course name', prefixIcon: Icon(Icons.book_outlined, size: 18))),
          const SizedBox(height: 10),
          TextFormField(controller: _semesterCtrl,
              decoration: const InputDecoration(labelText: 'Semester (e.g. Spring 2025)', prefixIcon: Icon(Icons.calendar_today_outlined, size: 18))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _grade,
                  decoration: const InputDecoration(labelText: 'Grade'),
                  items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) => setState(() => _grade = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _credits,
                  decoration: const InputDecoration(labelText: 'Credits'),
                  items: [1, 2, 3, 4, 5].map((c) => DropdownMenuItem(value: c, child: Text('$c cr'))).toList(),
                  onChanged: (v) => setState(() => _credits = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_isEdit ? 'Save changes' : 'Save Grade'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_courseCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final userId = ref.read(authServiceProvider).currentUser!.id;
    final existing = widget.existing;

    final grade = Grade(
      id: existing?.id ?? const Uuid().v4(),
      courseId: existing?.courseId ?? const Uuid().v4(),
      courseName: _courseCtrl.text.trim(),
      creditHours: _credits,
      letterGrade: _grade,
      gradePoints: Grade.letterToPoints(_grade),
      userId: userId,
      semester: _semesterCtrl.text.trim(),
    );

    await ref.read(dbServiceProvider).upsertGrade(grade);
    ref.invalidate(gradesProvider);
    ref.invalidate(cgpaProvider);
    if (mounted) Navigator.pop(context);
  }
}