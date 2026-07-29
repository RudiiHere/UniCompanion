import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';


class TaskType {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const TaskType({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  static const assignment = TaskType(
    id: 'assignment', label: 'Assignment',
    icon: Icons.assignment_outlined, color: AppTheme.indigo, bgColor: AppTheme.indigoSoft,
  );
  static const lab = TaskType(
    id: 'lab', label: 'Lab',
    icon: Icons.science_outlined, color: AppTheme.emerald, bgColor: AppTheme.emeraldSoft,
  );
  static const classTest = TaskType(
    id: 'class_test', label: 'Class Test',
    icon: Icons.quiz_outlined, color: AppTheme.amber, bgColor: AppTheme.amberSoft,
  );
  static const presentation = TaskType(
    id: 'presentation', label: 'Presentation',
    icon: Icons.slideshow_outlined, color: AppTheme.sky, bgColor: AppTheme.skySoft,
  );
  static const viva = TaskType(
    id: 'viva', label: 'Viva',
    icon: Icons.record_voice_over_outlined, color: AppTheme.violet, bgColor: AppTheme.violetSoft,
  );

  static const List<TaskType> all = [assignment, lab, classTest, presentation, viva];

  static TaskType fromId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => assignment);
}


final taskFilterProvider = StateProvider<String?>((ref) => null);

class AssignmentsScreen extends ConsumerWidget {
  const AssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(assignmentsProvider);
    final filter = ref.watch(taskFilterProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAddSheet(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: assignmentsAsync.when(
        data: (all) {
          final tasks = filter == null ? all : all.where((a) => a.type == filter).toList();

          return Column(
            children: [
              _StatsHeader(all: all),
              _FilterBar(all: all),
              Divider(height: 0.5, color: cs.outline),
              Expanded(
                child: tasks.isEmpty
                    ? EmptyState(
                  icon: Icons.checklist_rounded,
                  title: filter == null ? 'No tasks yet' : 'No ${TaskType.fromId(filter).label.toLowerCase()} tasks',
                  subtitle: 'Tap Add to create your first task',
                  action: ElevatedButton.icon(
                    onPressed: () => _showAddSheet(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add task'),
                  ),
                )
                    : _TaskList(tasks: tasks, ref: ref),
              ),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ShimmerCard(height: 100),
          ),
        ),
        error: (error, stack) => const Center(child: Text('Could not load tasks')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(ref: ref),
    );
  }
}


class _StatsHeader extends StatelessWidget {
  final List<Assignment> all;
  const _StatsHeader({required this.all});

  @override
  Widget build(BuildContext context) {
    final pending = all.where((a) => a.status != 'done' && !a.isOverdue).length;
    final overdue = all.where((a) => a.isOverdue).length;
    final done    = all.where((a) => a.status == 'done').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Expanded(child: StatCard(label: 'Pending', value: '$pending', color: AppTheme.amber, bgColor: AppTheme.amberSoft, icon: Icons.pending_actions_rounded)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Overdue', value: '$overdue', color: AppTheme.rose, bgColor: AppTheme.roseSoft, icon: Icons.warning_amber_rounded)),
          const SizedBox(width: 10),
          Expanded(child: StatCard(label: 'Done', value: '$done', color: AppTheme.emerald, bgColor: AppTheme.emeraldSoft, icon: Icons.check_circle_outline_rounded)),
        ],
      ),
    );
  }
}


class _FilterBar extends ConsumerWidget {
  final List<Assignment> all;
  const _FilterBar({required this.all});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskFilterProvider);
    final cs = Theme.of(context).colorScheme;

    Widget chip({required String label, required bool sel, required Color color, required VoidCallback onTap, int? count}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: sel ? color : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: sel ? color : cs.outline, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : cs.onSurfaceVariant)),
                if (count != null && count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sel ? Colors.white : color)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip(
              label: 'All',
              sel: filter == null,
              color: AppTheme.indigo,
              count: all.length,
              onTap: () => ref.read(taskFilterProvider.notifier).state = null,
            ),
            ...TaskType.all.map((t) {
              final count = all.where((a) => a.type == t.id).length;
              return chip(
                label: t.label,
                sel: filter == t.id,
                color: t.color,
                count: count,
                onTap: () => ref.read(taskFilterProvider.notifier).state = t.id,
              );
            }),
          ],
        ),
      ),
    );
  }
}


class _TaskList extends StatelessWidget {
  final List<Assignment> tasks;
  final WidgetRef ref;
  const _TaskList({required this.tasks, required this.ref});

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((a) => a.status != 'done').toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final done = tasks.where((a) => a.status == 'done').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionLabel(title: 'To do', count: pending.length, color: AppTheme.rose),
          const SizedBox(height: 10),
          ...pending.map((a) => _TaskCard(assignment: a, ref: ref)),
          const SizedBox(height: 20),
        ],
        if (done.isNotEmpty) ...[
          _SectionLabel(title: 'Completed', count: done.length, color: AppTheme.emerald),
          const SizedBox(height: 10),
          ...done.map((a) => _TaskCard(assignment: a, ref: ref)),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  const _SectionLabel({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(100)),
        child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }
}

class _TaskCard extends StatelessWidget {
  final Assignment assignment;
  final WidgetRef ref;
  const _TaskCard({required this.assignment, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isDone    = assignment.status == 'done';
    final isOverdue = assignment.isOverdue;
    final taskType  = TaskType.fromId(assignment.type);
    final cs = Theme.of(context).colorScheme;

    Color accentColor;
    if (isDone) {
      accentColor = AppTheme.emerald;
    } else if (isOverdue) {
      accentColor = AppTheme.rose;
    } else if (assignment.daysUntilDue <= 2) {
      accentColor = AppTheme.amber;
    } else {
      accentColor = taskType.color;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _openEditSheet(context),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: taskType.bgColor, borderRadius: BorderRadius.circular(10)),
                    child: Icon(isDone ? Icons.check_circle_rounded : taskType.icon, size: 19, color: isDone ? AppTheme.emerald : taskType.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(children: [
                          Text(taskType.label, style: TextStyle(fontSize: 11, color: taskType.color, fontWeight: FontWeight.w600)),
                          Text('  ·  ${assignment.courseName}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        ]),
                      ],
                    ),
                  ),
                  _StatusBadge(assignment: assignment),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: assignment.progressPercent / 100.0,
                  minHeight: 6,
                  backgroundColor: cs.outline.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation(accentColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Row(children: [
                    Icon(Icons.event_outlined, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(DateFormat('d MMM').format(assignment.dueDate), style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
                    Text('  ·  ${assignment.progressPercent}%', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                  ]),
                  const Spacer(),
                  if (!isDone) ...[
                    _ActionChip(label: 'Update', color: AppTheme.indigo, onTap: () => _updateProgress(context)),
                    const SizedBox(width: 8),
                    _ActionChip(label: 'Done ✓', color: AppTheme.emerald, onTap: _markDone),
                  ] else
                    _ActionChip(label: 'Delete', color: AppTheme.rose, onTap: _delete),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(ref: ref, task: assignment),
    );
  }

  void _markDone() {
    ref.read(dbServiceProvider).updateAssignment(assignment.copyWith(status: 'done', progressPercent: 100));
    ref.invalidate(assignmentsProvider);
  }

  void _delete() {
    ref.read(dbServiceProvider).deleteAssignment(assignment.id);
    ref.invalidate(assignmentsProvider);
  }

  void _updateProgress(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        int progress = assignment.progressPercent;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Update progress', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$progress%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
                Slider(
                  value: progress.toDouble(), min: 0, max: 100, divisions: 20,
                  activeColor: AppTheme.indigo,
                  onChanged: (v) => setState(() => progress = v.round()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
                onPressed: () {
                  final newStatus = progress >= 100 ? 'done' : 'pending';
                  ref.read(dbServiceProvider).updateAssignment(assignment.copyWith(progressPercent: progress, status: newStatus));
                  ref.invalidate(assignmentsProvider);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Assignment assignment;
  const _StatusBadge({required this.assignment});

  @override
  Widget build(BuildContext context) {
    if (assignment.status == 'done')  return const BadgePill(label: 'Done',      color: AppTheme.emerald, bgColor: AppTheme.emeraldSoft);
    if (assignment.isOverdue)         return const BadgePill(label: 'Overdue',   color: AppTheme.rose,    bgColor: AppTheme.roseSoft);
    if (assignment.daysUntilDue == 0) return const BadgePill(label: 'Due today', color: AppTheme.rose,    bgColor: AppTheme.roseSoft);
    if (assignment.daysUntilDue <= 2) return BadgePill(label: 'Due in ${assignment.daysUntilDue}d', color: AppTheme.amber, bgColor: AppTheme.amberSoft);
    return BadgePill(label: 'Due in ${assignment.daysUntilDue}d', color: AppTheme.sky, bgColor: AppTheme.skySoft);
  }
}


class _AddTaskSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Assignment? task;
  const _AddTaskSheet({required this.ref, this.task});

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _courseCtrl = TextEditingController();
  String _type = TaskType.assignment.id;
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _titleCtrl.text  = t.title;
      _descCtrl.text   = t.description ?? '';
      _courseCtrl.text = t.courseName;
      _type    = t.type;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _courseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Text(_isEditing ? 'Edit Task' : 'New Task', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),

            Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: TaskType.all.map((t) {
                final sel = t.id == _type;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? t.color : t.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? t.color : t.color.withValues(alpha: 0.2), width: sel ? 0 : 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, size: 15, color: sel ? Colors.white : t.color),
                        const SizedBox(width: 6),
                        Text(t.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : t.color)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', prefixIcon: Icon(Icons.title_rounded, size: 18)),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _courseCtrl,
              decoration: const InputDecoration(labelText: 'Course name', prefixIcon: Icon(Icons.school_outlined, size: 18)),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.notes_rounded, size: 18)),
              maxLines: 2,
            ),
            const SizedBox(height: 10),

            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 3)),
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _dueDate != null ? AppTheme.indigo : cs.outline, width: _dueDate != null ? 1.5 : 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: _dueDate != null ? AppTheme.indigo : cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(
                    _dueDate == null ? 'Select due date' : DateFormat('EEEE, d MMM yyyy').format(_dueDate!),
                    style: TextStyle(fontSize: 14, color: _dueDate == null ? cs.onSurfaceVariant : cs.onSurface, fontWeight: _dueDate != null ? FontWeight.w500 : FontWeight.w400),
                  ),
                ]),
              ),
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
                  : Text(_isEditing ? 'Save Changes' : 'Add Task'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a title');
      return;
    }
    if (_courseCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a course name');
      return;
    }
    if (_dueDate == null) {
      setState(() => _error = 'Please select a due date');
      return;
    }

    setState(() => _saving = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() { _saving = false; _error = 'You must be signed in'; });
      return;
    }

    try {
      final db = ref.read(dbServiceProvider);
      if (_isEditing) {
        final original = widget.task!;
        final edited = Assignment(
          id: original.id,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          courseId: original.courseId,
          courseName: _courseCtrl.text.trim(),
          dueDate: _dueDate!,
          status: original.status,
          progressPercent: original.progressPercent,
          type: _type,
          userId: original.userId,
          createdAt: original.createdAt,
        );
        await db.editAssignment(edited);
      } else {
        final task = Assignment(
          id: const Uuid().v4(),
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          courseId: const Uuid().v4(),
          courseName: _courseCtrl.text.trim(),
          dueDate: _dueDate!,
          type: _type,
          userId: user.id,
          createdAt: DateTime.now(),
        );
        await db.addAssignment(task);
      }
      ref.invalidate(assignmentsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save. Check your connection and try again.'; });
    }
  }
}