// lib/widgets/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../config/app_theme.dart';
import 'common_widgets.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location == '/') return 0;
    if (location.startsWith('/routine')) return 1;
    if (location.startsWith('/assignments')) return 2;
    if (location.startsWith('/ai')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/', '/routine', '/assignments', '/ai', '/profile'];
    context.go(routes[index]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final isOnline = ref.watch(isOnlineProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF12121E) : Colors.white;

    // Back button: only the dashboard ("/") exits the app. Everywhere else,
    // back returns to the dashboard. This handler sits on the shell route
    // (the root navigator's page); the per-screen wrappers in app_router.dart
    // cover the case where go_router routes the back press to the inner
    // navigator instead. Between the two, the back press is always caught.
    final isHome = location == '/';

    return PopScope(
        canPop: isHome,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.go('/');
        },
        child: Scaffold(
          body: Column(
            children: [
              if (!isOnline) const OfflineBanner(),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 60,
                child: Row(
                  children: [
                    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, onTap: () => _onTap(context, 0)),
                    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month_rounded, label: 'Schedule', index: 1, current: currentIndex, onTap: () => _onTap(context, 1)),
                    _NavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Tasks', index: 2, current: currentIndex, onTap: () => _onTap(context, 2)),
                    _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'AI', index: 3, current: currentIndex, onTap: () => _onTap(context, 3)),
                    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile', index: 4, current: currentIndex, onTap: () => _onTap(context, 4)),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    final cs = Theme.of(context).colorScheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? cs.primary.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(selected ? activeIcon : icon, size: 21, color: color),
            ),
            const SizedBox(height: 1),
            Text(label, style: TextStyle(fontSize: 9.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: color)),
          ],
        ),
      ),
    );
  }
}