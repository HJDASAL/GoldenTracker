/*
Contains all the routes in the app in the singleton [Routes]
 */

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_tracker_enterprise/widgets/session_screen.dart';

import 'models/screen.dart';
import 'screens/index.dart';
import 'widgets/index.dart';

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
    GoScreen('/login', builder: (context, state, args) {
      return LoginScreen(
        initialAuthorizedLocation: '/',
        logOutUsername: args['logOutUsername'] as String?,
      );
    }),
    StatefulShellScreen(
      '/',
      builder: (context, state, shell, subScreens, args) {
        return Dashboard(
          navigationShell: shell,
          subScreens: subScreens,
          session: args['session'] as Session,
        );
      },
      subScreens: [
        GoScreen(
          '/',
          label: 'Home',
          icon: Icons.home,
          builder: (context, state, args) {
            return HomeScreen(session: args['session'] as Session);
          },
        ),
        GoScreen(
          '/approval',
          label: 'Approval',
          icon: Icons.assignment_turned_in_outlined,
          builder: (context, state, args) => ApprovalScreen(),
        ),
      ],
    ),
  ];
}
