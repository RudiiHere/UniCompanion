import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/routine_import_sheet.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  static const _days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay     = ref.watch(selectedDayProvider);
    final dayRoutineAsync = ref.watch(dayRoutineProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Routine'),
        actions: [
          IconButton(
            tooltip: 'Auto-import routine',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: () => showRoutineImportSheet(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAddSheet(context, ref, selectedDay),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Day chips ───────────────────────────────────────────────────
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: _days.map((day) {
                final sel = day == selectedDay;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => ref.read(selectedDayProvider.notifier).state = day,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: sel ? cs.primary : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? cs.primary : cs.outline, width: sel ? 0 : 0.5),
                        ),
                        child: Text(
                          day.substring(0, 3),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : cs.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 0.5, color: cs.outline),

          // ── Slots ────────────────────────────────────────────────────────
          Expanded(
            child: dayRoutineAsync.when(
              data: (slots) => slots.isEmpty
                  ? EmptyState(
                icon: Icons.event_note_outlined,
                title: 'No classes on $selectedDay',
                subtitle: 'Tap below to add your first class for this day',
                action: ElevatedButton.icon(
                  onPressed: () => _showAddSheet(context, ref, selectedDay),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add class'),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: slots.length,
                itemBuilder: (context, i) => _SlotCard(
                  slot: slots[i],
                  onDelete: () => _confirmDelete(context, ref, slots[i]),
                ),
              ),
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: ShimmerCard(height: 90),
                ),
              ),
              error: (_, __) => const Center(child: Text('Could not load routine')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref, selectedDay),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref, String day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddClassSheet(ref: ref, initialDay: day),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ClassSlot slot) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete class?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Remove "${slot.courseName}" from ${slot.dayOfWeek}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose, minimumSize: const Size(90, 40)),
            onPressed: () async {
              await ref.read(dbServiceProvider).deleteClassSlot(slot.id);
              ref.invalidate(routineProvider);
              ref.invalidate(dayRoutineProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  final ClassSlot slot;
  final VoidCallback onDelete;
  const _SlotCard({required this.slot, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color   = courseColor(slot.courseId);
    final bgColor = courseBgColor(slot.courseId);
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(slot.startTime, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text(slot.endTime, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Line + dot
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                margin: const EdgeInsets.only(top: 16),
              ),
              Container(width: 1.5, height: 60, color: color.withValues(alpha: 0.2)),
            ],
          ),
          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slot.courseName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color, letterSpacing: -0.2)),
                        if (slot.courseCode.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(slot.courseCode, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                        ],
                        if (slot.room != null && slot.room!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.location_on_outlined, size: 12, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Room ${slot.room}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.delete_outline_rounded, size: 18, color: color.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddClassSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final String initialDay;
  const _AddClassSheet({required this.ref, required this.initialDay});

  @override
  ConsumerState<_AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends ConsumerState<_AddClassSheet> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  late String _day;
  TimeOfDay? _start;
  TimeOfDay? _end;
  bool _saving = false;
  String? _error;

  static const _days = ['Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
          const Text('Add Class', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),

          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Course name', prefixIcon: Icon(Icons.menu_book_rounded, size: 18)),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(labelText: 'Course code (e.g. CSE220)', prefixIcon: Icon(Icons.tag_rounded, size: 18)),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _roomCtrl,
            decoration: const InputDecoration(labelText: 'Room (optional)', prefixIcon: Icon(Icons.location_on_outlined, size: 18)),
          ),
          const SizedBox(height: 14),

          // Day selector
          Text('Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _days.map((d) {
                final sel = d == _day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _day = d),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.indigo : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: sel ? AppTheme.indigo : cs.outline, width: 0.5),
                      ),
                      child: Text(d.substring(0, 3),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : cs.onSurfaceVariant)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Time pickers
          Row(
            children: [
              Expanded(child: _TimeField(label: 'Start', value: _start, onTap: () => _pickTime(true))),
              const SizedBox(width: 12),
              Expanded(child: _TimeField(label: 'End', value: _end, onTap: () => _pickTime(false))),
            ],
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.rose, fontSize: 12, fontWeight: FontWeight.w500)),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Add Class'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_start ?? const TimeOfDay(hour: 9, minute: 0)) : (_end ?? const TimeOfDay(hour: 10, minute: 30)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a course name');
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _error = 'Please select start and end times');
      return;
    }
    // Compare times in minutes to ensure end is after start
    final startMins = _start!.hour * 60 + _start!.minute;
    final endMins   = _end!.hour * 60 + _end!.minute;
    if (endMins <= startMins) {
      setState(() => _error = 'End time must be after start time');
      return;
    }

    setState(() => _saving = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      setState(() { _saving = false; _error = 'You must be signed in'; });
      return;
    }

    final slot = ClassSlot(
      id: const Uuid().v4(),
      courseId: const Uuid().v4(),
      courseName: _nameCtrl.text.trim(),
      courseCode: _codeCtrl.text.trim(),
      dayOfWeek: _day,
      startTime: _fmt(_start!),
      endTime: _fmt(_end!),
      room: _roomCtrl.text.trim().isEmpty ? null : _roomCtrl.text.trim(),
      userId: user.id,
    );

    try {
      await ref.read(dbServiceProvider).addClassSlot(slot);
      ref.invalidate(routineProvider);
      ref.invalidate(dayRoutineProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save. Check your connection and try again.'; });
    }
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  const _TimeField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final set = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: set ? AppTheme.indigo : cs.outline, width: set ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 18, color: set ? AppTheme.indigo : cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                Text(
                  value == null ? '--:--' : value!.format(context),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: set ? cs.onSurface : cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}