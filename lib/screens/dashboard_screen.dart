import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(currentProfileProvider);
    final cgpaAsync     = ref.watch(cgpaProvider);
    final assignmentsAsync = ref.watch(pendingAssignmentsProvider);
    final dayRoutineAsync  = ref.watch(dayRoutineProvider);
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(bottom: BorderSide(color: cs.outline, width: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              profileAsync.when(
                                data: (p) => Text(
                                  '${_greeting()}, ${p?.fullName.split(' ').first ?? 'Student'} 👋',
                                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.5),
                                ),
                                loading: () => const ShimmerCard(height: 24),
                                error: (_, __) => const Text('Hello 👋'),
                              ),
                              const SizedBox(height: 3),
                              Text(today, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/notices'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outline, width: 0.5),
                            ),
                            child: Icon(Icons.notifications_outlined, size: 20, color: cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Stats row
                    Row(children: [
                      Expanded(
                        child: cgpaAsync.when(
                          data: (v) => StatCard(
                            label: 'CGPA', value: v.toStringAsFixed(2),
                            color: AppTheme.indigo, bgColor: AppTheme.indigoSoft,
                            icon: Icons.grade_rounded,
                          ),
                          loading: () => const ShimmerCard(height: 88),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: assignmentsAsync.when(
                          data: (list) => StatCard(
                            label: 'Pending', value: '${list.length}',
                            color: AppTheme.amber, bgColor: AppTheme.amberSoft,
                            icon: Icons.task_alt_rounded,
                          ),
                          loading: () => const ShimmerCard(height: 88),
                          error: (_, __) => const SizedBox(),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Quick access'),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _QuickAction(icon: Icons.calendar_month_rounded, label: 'Routine',    color: AppTheme.indigo,   onTap: () => context.go('/routine')),
                        const SizedBox(width: 10),
                        _QuickAction(icon: Icons.task_alt_rounded,       label: 'Tasks',      color: AppTheme.emerald,  onTap: () => context.go('/assignments')),
                        const SizedBox(width: 10),
                        _QuickAction(icon: Icons.grade_rounded,          label: 'CGPA',       color: AppTheme.sky,      onTap: () => context.go('/cgpa')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _QuickAction(icon: Icons.campaign_rounded,       label: 'Notices',    color: AppTheme.rose,     onTap: () => context.go('/notices')),
                        const SizedBox(width: 10),
                        _QuickAction(icon: Icons.forum_rounded,          label: 'Chat',       color: AppTheme.violet,   onTap: () => context.go('/chat')),
                        const SizedBox(width: 10),
                        _QuickAction(icon: Icons.auto_awesome_rounded,   label: 'AI',         color: AppTheme.emerald,  onTap: () => context.go('/ai')),
                        const SizedBox(width: 10),
                        _QuickAction(icon: Icons.person_rounded,         label: 'Profile',    color: const Color(0xFF64748B), onTap: () => context.go('/profile')),
                      ],
                    ),
                  ],
                ),
              ),
            ),


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: "Today's classes",
                      trailing: TextButton(
                        onPressed: () => context.go('/routine'),
                        child: Text('See all', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    dayRoutineAsync.when(
                      data: (slots) => slots.isEmpty
                          ? AppCard(
                        child: Row(children: [
                          Icon(Icons.free_breakfast_outlined, color: cs.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Text('No classes today', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        ]),
                      )
                          : Column(
                        children: slots.map((s) {
                          final color = courseColor(s.courseId);
                          final bgColor = courseBgColor(s.courseId);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: AppCard(
                              child: Row(children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.menu_book_rounded, size: 20, color: color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.courseName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                                      if (s.room != null)
                                        Text('Room ${s.room}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                ),
                                BadgePill(label: s.startTime, color: color, bgColor: bgColor),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                      loading: () => Column(children: List.generate(2, (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShimmerCard(height: 66),
                      ))),
                      error: (_, __) => const Text('Could not load schedule'),
                    ),
                  ],
                ),
              ),
            ),


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Pending assignments',
                      trailing: TextButton(
                        onPressed: () => context.go('/assignments'),
                        child: Text('See all', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    assignmentsAsync.when(
                      data: (assignments) {
                        final show = assignments.take(3).toList();
                        if (show.isEmpty) {
                          return AppCard(
                            child: Row(children: [
                              Icon(Icons.check_circle_outline_rounded, color: AppTheme.emerald),
                              const SizedBox(width: 10),
                              Text('All caught up!', style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                          );
                        }
                        return Column(
                          children: show.map((a) {
                            final isOverdue = a.isOverdue;
                            final badgeColor = isOverdue ? AppTheme.rose : AppTheme.amber;
                            final badgeBg    = isOverdue ? AppTheme.roseSoft : AppTheme.amberSoft;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AppCard(
                                child: Row(children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.assignment_outlined, size: 20, color: badgeColor),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
                                        Text(a.courseName, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  BadgePill(
                                    label: isOverdue ? 'Overdue' : 'Due in ${a.daysUntilDue}d',
                                    color: badgeColor, bgColor: badgeBg,
                                  ),
                                ]),
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => Column(children: List.generate(2, (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 8), child: ShimmerCard(height: 66),
                      ))),
                      error: (_, __) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 52, width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.2), width: 0.5),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}