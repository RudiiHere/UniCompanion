// lib/widgets/routine_import_sheet.dart
//
// Bottom sheet that auto-imports the routine. Student picks Department (from
// the admin-managed registry) + Batch + Section. The choice is saved to their
// profile so it's remembered. Importing replaces only the 'import' classes —
// anything added manually stays.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_providers.dart';
import '../services/routine_import_service.dart';
import '../models/app_models.dart';
import '../models/routine_source.dart';
import '../screens/routine_sources_screen.dart';

Future<void> showRoutineImportSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const RoutineImportSheet(),
  );
}

class RoutineImportSheet extends ConsumerStatefulWidget {
  const RoutineImportSheet({super.key});
  @override
  ConsumerState<RoutineImportSheet> createState() => _RoutineImportSheetState();
}

class _RoutineImportSheetState extends ConsumerState<RoutineImportSheet> {
  final _service = RoutineImportService();
  RoutineSource? _dept;
  String? _batch;
  String? _section;
  bool _busy = false;
  String? _error;
  List<ClassSlot>? _preview;
  bool _prefilled = false;

  void _prefill(List<RoutineSource> sources, UserProfile? profile) {
    if (_prefilled) return;
    _prefilled = true;
    _batch ??= profile?.batch ?? RoutineImportService.batches.first;
    _section ??= profile?.section ?? RoutineImportService.sections.first;
    if (_dept == null && sources.isNotEmpty) {
      _dept = sources.firstWhere(
            (s) => s.department == profile?.department,
        orElse: () => sources.first,
      );
    }
  }

  Future<void> _fetch() async {
    if (_dept == null) return;
    setState(() { _busy = true; _error = null; _preview = null; });
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      final slots = await _service.fetchRoutine(
        sheetId: _dept!.sheetId, batch: _batch!, section: _section!, userId: uid,
      );
      if (!mounted) return;
      if (slots.isEmpty) {
        setState(() => _error =
        'No classes found for ${_dept!.department}, Batch $_batch, '
            'Section $_section. Double-check your batch and section.');
      } else {
        setState(() => _preview = slots);
      }
    } on RoutineImportException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    setState(() { _busy = true; _error = null; });
    try {
      final db = ref.read(dbServiceProvider);
      await db.replaceImportedRoutine(_preview!);
      await db.updateRoutinePrefs(
        department: _dept!.department, batch: _batch, section: _section,
      );
      ref.invalidate(routineProvider);
      ref.invalidate(dayRoutineProvider);
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${_preview!.length} classes · '
            '${_dept!.department} ${_batch}${_section}')),
      );
    } catch (_) {
      if (mounted) setState(() { _busy = false; _error = 'Could not save the routine. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isAdmin = ref.watch(currentProfileProvider).valueOrNull?.role == 'admin';
    final sourcesAsync = ref.watch(routineSourcesProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.cloud_download_outlined, color: cs.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Auto-import routine',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            if (isAdmin)
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RoutineSourcesScreen())),
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Manage'),
              ),
          ]),
          const SizedBox(height: 4),
          Text('Pull your weekly routine straight from your department sheet.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 18),

          sourcesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => _errorText(cs, 'Could not load departments. Check your connection.'),
            data: (sources) {
              final profile = ref.watch(currentProfileProvider).valueOrNull;
              _prefill(sources, profile);

              if (sources.isEmpty) {
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _errorText(cs, 'No departments have been added yet.'),
                  if (isAdmin)
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const RoutineSourcesScreen())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add a department'),
                    ),
                ]);
              }

              if (_preview != null) return _previewView(cs);

              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _deptDropdown(sources),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _dropdown('Batch', _batch!, RoutineImportService.batches,
                          (v) => setState(() => _batch = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _dropdown('Section', _section!, RoutineImportService.sections,
                          (v) => setState(() => _section = v))),
                ]),
                const SizedBox(height: 16),
                if (_error != null) _errorBox(cs),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _fetch,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search),
                    label: Text(_busy ? 'Fetching…' : 'Fetch routine'),
                  ),
                ),
              ]);
            },
          ),
        ],
      ),
    );
  }

  Widget _previewView(ColorScheme cs) {
    final perDay = <String, int>{};
    for (final s in _preview!) {
      perDay[s.dayOfWeek] = (perDay[s.dayOfWeek] ?? 0) + 1;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Found ${_preview!.length} classes · ${_dept!.department} '
              'Batch $_batch, Section $_section',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            RoutineImportService.days
                .where((d) => perDay.containsKey(d))
                .map((d) => '$d: ${perDay[d]}')
                .join('   •   '),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      Text('This replaces previously imported classes. Classes you added '
          'manually are kept.', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      const SizedBox(height: 14),
      if (_error != null) _errorBox(cs),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: _busy ? null : () => setState(() => _preview = null),
          child: const Text('Back'),
        )),
        const SizedBox(width: 12),
        Expanded(child: FilledButton.icon(
          onPressed: _busy ? null : _apply,
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          label: const Text('Replace'),
        )),
      ]),
    ]);
  }

  Widget _deptDropdown(List<RoutineSource> sources) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Department',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RoutineSource>(
          value: _dept,
          isExpanded: true,
          items: sources.map((s) => DropdownMenuItem(value: s, child: Text(s.title))).toList(),
          onChanged: (v) => setState(() => _dept = v),
        ),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }

  Widget _errorText(ColorScheme cs, String msg) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(msg, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
  );

  Widget _errorBox(ColorScheme cs) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: cs.errorContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(_error!, style: TextStyle(fontSize: 12.5, color: cs.onErrorContainer)),
  );
}