import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n_extensions.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _routes = ['/', '/profiles', '/settings'];

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.home),
        label: context.l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.folder),
        label: context.l10n.navProfiles,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings),
        label: context.l10n.navSettings,
      ),
    ];
  }

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _routes.indexOf(location);
    return index >= 0 ? index : 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final isDesktop = Platform.isWindows || Platform.isLinux;
    final width = MediaQuery.of(context).size.width;
    final destinations = _buildDestinations(context);

    if (isDesktop || width > 600) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onDestinationSelected(context, i),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: d.icon,
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => _onDestinationSelected(context, i),
        destinations: destinations,
      ),
    );
  }
}
