// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/app_providers.dart';
import 'services/cache_service.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'utils/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive offline cache
  await CacheService.init();

  // Initialize Supabase
  // ⚠️ ACTION REQUIRED: Replace values in lib/config/supabase_config.dart
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Start connectivity monitor
  ConnectivityService.instance.init();

  // Initialize local task-reminder notifications
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: UniCompanionApp()));
}

class UniCompanionApp extends ConsumerStatefulWidget {
  const UniCompanionApp({super.key});

  @override
  ConsumerState<UniCompanionApp> createState() => _UniCompanionAppState();
}

class _UniCompanionAppState extends ConsumerState<UniCompanionApp> {
  @override
  void initState() {
    super.initState();
    // Mirror online state into provider — safe to call here, not inside build
    ConnectivityService.instance.onlineStream.listen((online) {
      ref.read(isOnlineProvider.notifier).state = online;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reschedule task reminders whenever the task list changes.
    ref.listen(assignmentsProvider, (prev, next) {
      next.whenData(NotificationService.instance.syncAll);
    });

    final router    = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider); // now a ThemeMode, not a bool

    return MaterialApp.router(
      title: 'UniCompanion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}