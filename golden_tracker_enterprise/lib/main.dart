import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'package:go_router/go_router.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:golden_tracker_enterprise/styles/colors.dart';

import 'styles/theme.dart';

import 'widgets/responsive_layout.dart';

import 'routes.dart';
import 'secret.dart';

void main() {
  FlavorConfig(
    name: kAppEnvironment.toUpperCase(),
    color: Colors.redAccent,
    location: BannerLocation.topStart,
    variables: kEnvironmentVariables,
  );

  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  runApp((kAppEnvironment == 'prod') ? MyApp() : FlavorBanner(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ColorScheme _colorScheme = kLightTheme;

  final Map<String, ColorScheme> _colorSchemes = {
    'light': kLightTheme,
    'dark': kDarkTheme,
    'light-high-contrast': kHighContrastLightTheme,
    'dark-high-contrast': kHighContrastDarkTheme,
  };

  final RouterConfig<Object> _router = GoRouter(
    routes: List.generate(Routes.screens.length, (i) {
      return GoRoute(
        path: Routes.screens[i].path,
        builder: Routes.screens[i].builder,
      );
    }),
    errorBuilder: Routes.errorScreenBuilder,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      colorSchemes: _colorSchemes,
      onChangeColorScheme: (newColorScheme) => setState(() {
        _colorScheme = newColorScheme;
      }),
      child: MaterialApp.router(
        routerConfig: _router,
        title: kAppName,
        theme: ThemeData(
          colorScheme: _colorScheme,
          appBarTheme: AppBarTheme.of(context).copyWith(
            backgroundColor: kSecondaryColor,
          ),
          textTheme: TextTheme(),
          buttonTheme: ButtonThemeData(),
          useMaterial3: true,
        ),
      ),
    );
  }
}
