import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_tracker_enterprise/styles/colors.dart';

import '../secret.dart' show kAppName;

/// Provides the details of an app screen
/// Designed to work with GoRouter, StatefulShellRoute where complex and nested screens are tracked as a Screen Object
abstract class Screen {
  Screen(
    this.path, {
    this.name,
    this.label,
    this.icon,
    this.subScreens = const [],
  });

  final String path;

  final String? name;
  final String? label;
  final IconData? icon;
  final List<Screen> subScreens;

  static List<RouteBase> generateRoutes(List<Screen> screens, GlobalKey<NavigatorState> rootNavigatorKey) {
    List<RouteBase> routes = [];

    for (int i = 0; i < screens.length; i++) {
      RouteBase newRoute;

      if (screens[i].runtimeType == GoScreen) {
        GoScreen screen = screens[i] as GoScreen;
        newRoute = GoRoute(
          path: screen.path,
          builder: (context, state) {
            setScreenTitle(screens[i].name ?? kAppName, context);
            return screen.builder(
              context,
              state,
              (state.extra as Map<String, dynamic>?) ?? {},
            );
          },
          routes: generateRoutes(screen.subScreens, rootNavigatorKey),
        );
      } else if (screens[i].runtimeType == StatefulShellScreen) {
        StatefulShellScreen screen = screens[i] as StatefulShellScreen;

        newRoute = StatefulShellRoute.indexedStack(
          parentNavigatorKey: rootNavigatorKey,
          branches: List.generate(screen.subScreens.length, (j) {
            return StatefulShellBranch(
              routes: generateRoutes([screen.subScreens[j]], rootNavigatorKey),
            );
          }),
          builder: (context, state, navigationShell) {
            return screen.builder(
              context,
              state,
              navigationShell,
              screen.subScreens,
              (state.extra as Map<String, dynamic>?) ?? {},
            );
          },
        );
      } else {
        ShellScreen screen = screens[i] as ShellScreen;

        newRoute = ShellRoute(
          parentNavigatorKey: rootNavigatorKey,
          routes: generateRoutes(screens[i].subScreens, rootNavigatorKey),
          builder: (context, state, shell) {
            return screen.builder(
              context,
              state,
              shell,
              screen.subScreens,
              (state.extra as Map<String, dynamic>?) ?? {},
            );
          },
        );
      }

      routes.add(newRoute);
    }

    return routes;
  }
}

class GoScreen extends Screen {
  GoScreen(
    super.path, {
    required this.builder,
    super.label,
    super.icon,
    super.subScreens,
  });

  final Widget Function(
    BuildContext,
    GoRouterState, 
    Map<String, dynamic> args,
  ) builder;
}

class ShellScreen extends Screen {
  ShellScreen(
    super.path, {
    required this.builder,
    super.label,
    super.icon,
    super.subScreens,
  });

  final Widget Function(
    BuildContext,
    GoRouterState,
    Widget,
    List<Screen>, 
  Map<String, dynamic>? args,
  ) builder;
}

class StatefulShellScreen extends Screen {
  StatefulShellScreen(
    super.path, {
    required this.builder,
    super.label,
    super.icon,
    super.subScreens,
  });

  final Widget Function(
    BuildContext,
    GoRouterState,
    StatefulNavigationShell,
    List<Screen>, 
    Map<String, dynamic> args,
  ) builder;
}

// This function is used to update the page title
void setScreenTitle(String title, BuildContext context) {
  SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
    label: title,
    primaryColor: kPrimary.value, // This line is required
  ));
}
