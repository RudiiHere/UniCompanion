// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_theme.dart';

// ── Stat card ─────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData? icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon ?? Icons.bar_chart_rounded, size: 15, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.7), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Badge pill ────────────────────────────────────────────────────────────────
class BadgePill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData? icon;

  const BadgePill({super.key, required this.label, required this.color, required this.bgColor, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.2)),
        ],
      ),
    );
  }
}

// ── Labeled progress bar ──────────────────────────────────────────────────────
class LabeledProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String? trailingLabel;

  const LabeledProgressBar({super.key, required this.label, required this.value, required this.color, this.trailingLabel});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(0);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
            Text(
              trailingLabel ?? '$pct%',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────
class ShimmerCard extends StatelessWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E1E30) : const Color(0xFFE8EAF0),
      highlightColor: isDark ? const Color(0xFF2A2A40) : const Color(0xFFF5F6FA),
      child: Container(
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// ── Offline banner ────────────────────────────────────────────────────────────
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 20),
      color: AppTheme.amber,
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text('No internet — showing cached data', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.1,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, size: 34, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 20), SizedBox(width: 200, child: action!)],
          ],
        ),
      ),
    );
  }
}

// ── App card container ────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline, width: 0.5),
      ),
      child: child,
    );
  }
}

// ── Course colors ─────────────────────────────────────────────────────────────
Color courseColor(String courseId) {
  final colors = [
    AppTheme.indigo, AppTheme.emerald, AppTheme.amber,
    AppTheme.rose, AppTheme.sky, AppTheme.violet,
    const Color(0xFF0891B2), // cyan
  ];
  return colors[courseId.hashCode.abs() % colors.length];
}

Color courseBgColor(String courseId) {
  final colors = [
    AppTheme.indigoSoft, AppTheme.emeraldSoft, AppTheme.amberSoft,
    AppTheme.roseSoft, AppTheme.skySoft, AppTheme.violetSoft,
    const Color(0xFFECFEFF),
  ];
  return colors[courseId.hashCode.abs() % colors.length];
}
