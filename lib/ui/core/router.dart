import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/shell/app_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/vision/vision_screen.dart';
import '../screens/settings/settings_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/chat',
  routes: [
    GoRoute(
      path: '/settings',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/chat', builder: (context, state) => const ChatScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/vision', builder: (context, state) => const VisionScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen())]),
      ],
    ),
  ],
);