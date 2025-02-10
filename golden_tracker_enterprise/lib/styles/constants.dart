import 'package:flutter/material.dart';
import 'colors.dart';

final BorderRadius kNormalBorderRadius = BorderRadius.circular(8);

final InputDecoration kInputDecorationVariant = InputDecoration(
  focusColor: kOnSurface,
  floatingLabelStyle: TextStyle(fontWeight: FontWeight.bold, color: kOnSurface),
  focusedBorder: kInputBorderVariant,
);

final OutlineInputBorder kInputBorderVariant = OutlineInputBorder(
  borderSide: BorderSide(color: kOnSurface, width: 1.5),
  borderRadius: kNormalBorderRadius,
);

final InputDecorationTheme kInputDecorationTheme = InputDecorationTheme(
  border: OutlineInputBorder(borderRadius: kNormalBorderRadius),
  labelStyle: TextStyle(color: kOnSecondary),
  filled: true,
  fillColor: kSurface,
  hoverColor: kSurface,
);

final TextButtonThemeData kButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    backgroundColor: kPrimary,
    foregroundColor: kOnPrimary,
  ),
);
