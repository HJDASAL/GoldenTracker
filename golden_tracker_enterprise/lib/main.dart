import 'dart:developer';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:go_router/go_router.dart';
import 'package:flutter_flavor/flutter_flavor.dart';
import 'package:hive/hive.dart';

import 'local_entities/index.dart';

import 'styles/index.dart';

import 'models/screen.dart' show Screen;

import 'widgets/responsive_layout.dart';

import 'routes.dart';
import 'secret.dart';

void main() async {
  FlavorConfig(
    name: kAppEnvironment.toUpperCase(),
    color: Colors.redAccent,
    location: BannerLocation.bottomStart,
    variables: kEnvironmentVariables,
  );

  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    final appDirectory = await getApplicationSupportDirectory();
    kLocalStoragePath = appDirectory.path;
  } else {
    kLocalStoragePath = './';
  }

  Hive.init(kLocalStoragePath);

  usePathUrlStrategy();

  runApp((kAppEnvironment == 'prod') ? MyApp() : FlavorBanner(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();

  /// The current theme applied throughout the app
  ColorScheme _colorScheme = kLightTheme;

  /// available themes that can be applied through out the app
  final Map<String, ColorScheme> _colorSchemes = {
    'light': kLightTheme,
    'dark': kDarkTheme,
    'light-high-contrast': kHighContrastLightTheme,
    'dark-high-contrast': kHighContrastDarkTheme,
  };

  late final RouterConfig<Object> _router;

  @override
  void initState() {
    _router = GoRouter(
      initialLocation: '/login',
      navigatorKey: _rootNavigatorKey,
      routes: Screen.generateRoutes(Routes.screens, _rootNavigatorKey),
      errorBuilder: Routes.errorScreenBuilder,
    );

    _initializeLocalStorage();

    super.initState();
  }

  /// Opens/creates a [BoxCollection] object from [Hive] (a local storage management dependency) and registers adapters for custom defined objects
  void _initializeLocalStorage() async {
    await BoxCollection.open(
      kLocalStorageName, // Name of your database
      kLocalStorageBoxNames, // Names of your boxes
      // Path where to store your boxes (Only used in Flutter / Dart IO)
      path: path.join(kLocalStoragePath, kLocalStorageName),
      // Key to encrypt your boxes (Only used in Flutter / Dart IO)
      key: HiveAesCipher(kLocalStorageKey.codeUnits),
    );

    Hive.registerAdapter(SessionAdapter(0), override: true);
  }

  void _changeTheme(ColorScheme newColorScheme) {
    setState(() => _colorScheme = newColorScheme);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      colorSchemes: _colorSchemes,
      onChangeColorScheme: _changeTheme,
      child: MaterialApp.router(
        routerConfig: _router,
        title: kAppName,
        theme: ThemeData(
          colorScheme: _colorScheme,
          appBarTheme: AppBarTheme.of(context).copyWith(
            backgroundColor: kSecondary,
          ),
          inputDecorationTheme: kInputDecorationTheme,
          textButtonTheme: kButtonTheme,
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          useMaterial3: true,
        ),
      ),
    );
  }
}
