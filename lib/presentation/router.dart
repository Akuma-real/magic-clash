import 'package:go_router/go_router.dart';

import 'screens/home/home_screen.dart';
import 'screens/proxies/proxies_screen.dart';
import 'screens/connections/connections_screen.dart';
import 'screens/logs/logs_screen.dart';
import 'screens/configs/configs_screen.dart';
import 'screens/configs/config_editor_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/main_shell.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/proxies',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProxiesScreen(),
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
          path: '/configs',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ConfigsScreen(),
          ),
        ),
        GoRoute(
          path: '/configs/edit',
          redirect: (context, state) {
            if (state.extra is! String) return '/configs';
            return null;
          },
          builder: (context, state) => ConfigEditorScreen(
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
