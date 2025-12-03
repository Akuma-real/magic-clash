import 'package:go_router/go_router.dart';

import 'common/main_shell.dart';
import 'features/connections/connections_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/logs/logs_screen.dart';
import 'features/profiles/profile_editor_screen.dart';
import 'features/profiles/profiles_screen.dart';
import 'features/proxy/proxy_screen.dart';
import 'features/settings/settings_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/proxies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProxyScreen(),
          ),
        ),
        GoRoute(
          path: '/connections',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConnectionsScreen(),
          ),
        ),
        GoRoute(
          path: '/logs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LogsScreen(),
          ),
        ),
        GoRoute(
          path: '/profiles',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfilesScreen(),
          ),
        ),
        GoRoute(
          path: '/profiles/edit',
          redirect: (context, state) {
            if (state.extra is! String) return '/profiles';
            return null;
          },
          builder: (context, state) => ProfileEditorScreen(
            configId: state.extra as String,
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);
