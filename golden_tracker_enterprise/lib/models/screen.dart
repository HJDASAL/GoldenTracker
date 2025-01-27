import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// use package reference format for file path if not in same directory or sub-directories
import '../secret.dart' show kAppName;

/// Provides the details of an app screen
/// Designed to work with GoRouter, StatefulShellRoute where complex and nested screens are tracked as a Screen Object
class Screen {
  const Screen({
    required this.builder,
    required this.path,
    this.name,
    this.label,
    this.icon,
    this.isShellRoute = false,
    this.keepShellState = false,
    this.subScreens = const [],
  });

  final Widget Function(BuildContext context, GoRouterState state) builder;

  /// Indicates if the screen will use a shell route and indexed stack for it's children routes (sub-screens)
  final bool isShellRoute;
  final bool keepShellState;

  /// The route path
  final String path;

  /// The route's display name (for updating app title)
  final String? name;

  /// The label shown in the navigation bar
  final String? label;

  /// The icon shown beside the label in the navigation bar
  final Icon? icon;

  /// The list of [Screen]s succeeding in the current [Screen]
  /// The [subScreens]' paths would be concatenated to the current [Screen] path
  /// if [isShellRoute] is true, the [subScreens] would be rendered in an indexed stack
  final List<Screen> subScreens;

  /// For creating the routes given the list of [Screen] details, primarily used for initializing the routes with GoRouter.
  static List<RouteBase> generateRoutes(List<Screen> screens) {
    return List.generate(screens.length, (i) {
      Screen screen = screens[i];
      return GoRoute(
        path: screen.path,
        builder: (context, state) {
          setPageTitle(screens[i].name ?? kAppName, context);
          return screen.builder(context, state);
        },
        routes: generateRoutes(screen.subScreens),
      );
    });
  }
}

// This function is used to update the page title
void setPageTitle(String title, BuildContext context) {
  SystemChrome.setApplicationSwitcherDescription(ApplicationSwitcherDescription(
    label: title,
    primaryColor: Theme.of(context).primaryColor.value, // This line is required
  ));
}
