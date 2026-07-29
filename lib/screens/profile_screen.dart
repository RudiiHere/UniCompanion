import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_providers.dart';
import '../../models/app_models.dart';
import '../../config/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openEdit(BuildContext context, WidgetRef ref, UserProfile profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
    );

    ref.invalidate(currentProfileProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync  = ref.watch(currentProfileProvider);
    final cgpaAsync     = ref.watch(cgpaProvider);
    final assignmentsAsync = ref.watch(pendingAssignmentsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          profileAsync.maybeWhen(
            data: (profile) => profile == null
                ? const SizedBox.shrink()
                : IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit profile',
              onPressed: () => _openEdit(context, ref, profile),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          profileAsync.when(
            data: (profile) {
              if (profile == null) return const SizedBox();
              final initials = profile.fullName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 66, height: 66,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                        imageUrl: profile.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 66, height: 66,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      )
                          : Center(child: Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.fullName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.4)),
                          const SizedBox(height: 3),
                          if (profile.department != null)
                            Text(profile.department!, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          if (profile.studentId != null) ...[
                            const SizedBox(height: 2),
                            Text('ID: ${profile.studentId}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                          ],
                          const SizedBox(height: 6),
                          Text(profile.email, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const ShimmerCard(height: 110),
            error: (_, __) => const SizedBox(),
          ),

          const SizedBox(height: 16),


          Row(children: [
            Expanded(
              child: cgpaAsync.when(
                data: (v) => StatCard(label: 'CGPA', value: v.toStringAsFixed(2), color: AppTheme.indigo, bgColor: AppTheme.indigoSoft, icon: Icons.grade_rounded),
                loading: () => const ShimmerCard(height: 80), error: (_, __) => const SizedBox(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: assignmentsAsync.when(
                data: (v) => StatCard(label: 'Pending', value: '${v.length}', color: AppTheme.amber, bgColor: AppTheme.amberSoft, icon: Icons.assignment_outlined),
                loading: () => const ShimmerCard(height: 80), error: (_, __) => const SizedBox(),
              ),
            ),
          ]),

          const SizedBox(height: 24),
          const SectionHeader(title: 'Academic'),
          const SizedBox(height: 10),
          _SettingsTile(icon: Icons.grade_rounded, color: AppTheme.indigo, label: 'CGPA Calculator', onTap: () => context.go('/cgpa')),
          _SettingsTile(icon: Icons.task_alt_rounded, color: AppTheme.amber, label: 'Assignments', onTap: () => context.go('/assignments')),
          _SettingsTile(icon: Icons.calendar_month_rounded, color: AppTheme.sky, label: 'Class Routine', onTap: () => context.go('/routine')),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Community'),
          const SizedBox(height: 10),
          _SettingsTile(icon: Icons.campaign_rounded, color: AppTheme.rose, label: 'Notice Board', onTap: () => context.go('/notices')),
          _SettingsTile(icon: Icons.forum_rounded, color: AppTheme.violet, label: 'Chat / Discussion', onTap: () => context.go('/chat')),

          const SizedBox(height: 20),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: 10),
          Consumer(
            builder: (_, ref, __) {
              final mode = ref.watch(themeModeProvider);
              return _SettingsTile(
                icon: mode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: const Color(0xFF64748B),
                label: 'Appearance',
                trailing: Text(
                  mode == ThemeMode.dark ? 'Dark' : mode == ThemeMode.light ? 'Light' : 'System',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                onTap: () => _showThemeSheet(context, ref),
              );
            },
          ),
          _SettingsTile(icon: Icons.notifications_outlined, color: const Color(0xFF64748B), label: 'Notifications', onTap: () {}),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.rose),
            label: const Text('Sign out', style: TextStyle(color: AppTheme.rose)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.rose.withOpacity(0.4)),
              foregroundColor: AppTheme.rose,
            ),
          ),
          const SizedBox(height: 32),
          Center(child: Text('UniCompanion v1.0.0', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showThemeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) {
        final cs = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: cs.outline, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              const Text('Appearance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...ThemeMode.values.map((mode) {
                final labels = {ThemeMode.system: 'System default', ThemeMode.light: 'Light', ThemeMode.dark: 'Dark'};
                final icons  = {ThemeMode.system: Icons.brightness_auto_rounded, ThemeMode.light: Icons.light_mode_rounded, ThemeMode.dark: Icons.dark_mode_rounded};
                final sel = ref.watch(themeModeProvider) == mode;
                return ListTile(
                  leading: Icon(icons[mode], color: sel ? AppTheme.indigo : cs.onSurfaceVariant),
                  title: Text(labels[mode]!, style: TextStyle(fontWeight: sel ? FontWeight.w700 : FontWeight.w400, color: sel ? AppTheme.indigo : cs.onSurface)),
                  trailing: sel ? const Icon(Icons.check_rounded, color: AppTheme.indigo, size: 18) : null,
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).set(mode);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({required this.icon, required this.color, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline, width: 0.5),
            ),
            child: Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface))),
              trailing ?? Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}