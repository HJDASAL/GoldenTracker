import 'package:flutter/material.dart';

import 'colors.dart';

final ColorScheme kLightTheme = ColorScheme(
  brightness: Brightness.light,
  // primary rules
  primary: kPrimary,
  onPrimary: kOnPrimary,
  primaryContainer: kPrimaryContainer,
  onPrimaryContainer: kOnPrimaryContainer,
  // secondary rules
  secondary: kSurface,
  onSecondary: kOnPrimary,
  secondaryContainer: kSecondaryContainer,
  onSecondaryContainer: kOnSecondaryContainer,
  // tertiary rules
  tertiary: kTertiary,
  onTertiary: kOnTertiary,
  tertiaryContainer: kTertiaryContainer,
  onTertiaryContainer: kOnTertiaryContainer,
  // error rules
  error: kError,
  onError: kOnError,
  // others
  surface: kSurface,
  onSurface: kOnSurface,
  outline: kOutline,
  outlineVariant: kOutlineVariant,
);

final ColorScheme kDarkTheme = ColorScheme.dark();

final ColorScheme kHighContrastLightTheme = ColorScheme.highContrastLight();

final ColorScheme kHighContrastDarkTheme = ColorScheme.highContrastDark();
