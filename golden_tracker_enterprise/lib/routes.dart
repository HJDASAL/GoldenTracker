/*
Contains all the routes in the app in the singleton [Routes]
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/screen.dart';
import 'screens/index.dart';

/// A singleton containing all the routes in the app
class Routes {
  Routes._();

  static Widget errorScreenBuilder(
    BuildContext context,
    GoRouterState state,
  ) {
    return ErrorPage();
  }

  static final List<Screen> screens = [
    Screen(
      builder: (context, routeState) {
        final args = routeState.extra as Map<String, dynamic>?; // passed info
        return HomeScreen();
      },
      path: '/',
    ),
    Screen(
      builder: (context, routeState) {
        return LoginScreen();
      },
      path: '/login',
    ),
  ];
}
