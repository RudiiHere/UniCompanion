import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/update_password_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/routine_screen.dart';
import '../screens/assignments_screen.dart';
import '../screens/cgpa_screen.dart';
import '../screens/notices_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/ai_assistant_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/main_shell.dart';

/// Wraps a screen so the Android back button returns to the dashboard instead
/// of exiting the app. The PopScope lives on the SCREEN, inside the shell's
/// navigator — the navigator go_router calls maybePop() on — which is why this
/// works where a PopScope on the shell did not.
class _BackToDashboard extends StatelessWidget {
  final Widget child;
  const _BackToDashboard({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: child,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [

      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),


      GoRoute(path: '/login',           builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register',        builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/update-password', builder: (c, s) => const UpdatePasswordScreen()),


      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/',            builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/routine',     builder: (c, s) => const _BackToDashboard(child: RoutineScreen())),
          GoRoute(path: '/assignments', builder: (c, s) => const _BackToDashboard(child: AssignmentsScreen())),
          GoRoute(path: '/cgpa',        builder: (c, s) => const _BackToDashboard(child: CgpaScreen())),
          GoRoute(path: '/notices',     builder: (c, s) => const _BackToDashboard(child: NoticesScreen())),
          GoRoute(path: '/chat',        builder: (c, s) => const _BackToDashboard(child: ChatScreen())),
          GoRoute(path: '/ai',          builder: (c, s) => const _BackToDashboard(child: AiAssistantScreen())),
          GoRoute(path: '/profile',     builder: (c, s) => const _BackToDashboard(child: ProfileScreen())),
        ],
      ),
    ],
  );
});