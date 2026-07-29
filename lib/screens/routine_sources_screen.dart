import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_providers.dart';
import '../../models/routine_source.dart';

class RoutineSourcesScreen extends ConsumerWidget {
  const RoutineSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(currentProfileProvider).valueOrNull?.role == 'admin';
    final sourcesAsync = ref.watch(allRoutineSourcesProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Routine Sources')),
        body: const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('This screen is for admins only.', textAlign: TextAlign.center),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Routine Sources')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add department'),
      ),
      body: sourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (sources) {
          if (sources.isEmpty) {
            return const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No departments yet. Tap “Add department” to create one.',
                  textAlign: TextAlign.center),
            ));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: sources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final s = sources[i];
              return Card(
                child: ListTile(
                  title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dept: ${s.department}'),
                      Text('Sheet: ${s.sheetId}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Switch(
                      value: s.active,
                      onChanged: (v) async {
                        await ref.read(dbServiceProvider)
                            .updateRoutineSource(s.copyWith(active: v));
                        ref.invalidate(allRoutineSourcesProvider);
                        ref.invalidate(routineSourcesProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openEditor(context, ref, existing: s),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, s),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, RoutineSource s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text('Remove “${s.title}” from the routine sources?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(dbServiceProvider).deleteRoutineSource(s.id);
      ref.invalidate(allRoutineSourcesProvider);
      ref.invalidate(routineSourcesProvider);
    }
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {RoutineSource? existing}) async {
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final urlCtrl = TextEditingController(text: existing?.sheetId ?? '');
    bool active = existing?.active ?? true;
    String? error;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add department' : 'Edit department'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: deptCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Department (e.g. CSE)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(labelText: 'Label (optional, e.g. CSE — Fall 2026)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Google Sheet link or ID',
                  hintText: 'https://docs.google.com/spreadsheets/d/…',
                ),
                maxLines: 2,
                minLines: 1,
              ),
              const SizedBox(height: 6),
              Row(children: [
                const Text('Active'),
                const Spacer(),
                Switch(value: active, onChanged: (v) => setState(() => active = v)),
              ]),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12.5)),
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final dept = deptCtrl.text.trim();
                final sheetId = RoutineSource.extractSheetId(urlCtrl.text);
                if (dept.isEmpty || sheetId.isEmpty) {
                  setState(() => error = 'Department and sheet link are required.');
                  return;
                }
                final db = ref.read(dbServiceProvider);
                final model = RoutineSource(
                  id: existing?.id ?? const Uuid().v4(),
                  department: dept,
                  sheetId: sheetId,
                  label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
                  active: active,
                );
                try {
                  if (existing == null) {
                    await db.addRoutineSource(model);
                  } else {
                    await db.updateRoutineSource(model);
                  }
                  ref.invalidate(allRoutineSourcesProvider);
                  ref.invalidate(routineSourcesProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  setState(() => error = 'Save failed: $e');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}