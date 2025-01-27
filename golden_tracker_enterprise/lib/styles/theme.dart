import 'package:flutter/material.dart';

import 'colors.dart';

final ColorScheme kLightTheme = ColorScheme(
  brightness: Brightness.light,
  primary: kPrimaryColor,
  onPrimary: kOnPrimaryColor,
  secondary: kSurfaceColor,
  onSecondary: kOnPrimaryColor,
  error: kErrorColor,
  onError: kOnErrorColor,
  surface: kSurfaceColor,
  onSurface: kOnSurfaceColor,
);

final ColorScheme kDarkTheme = ColorScheme.dark();

final ColorScheme kHighContrastLightTheme = ColorScheme.highContrastLight();

final ColorScheme kHighContrastDarkTheme = ColorScheme.highContrastDark();
