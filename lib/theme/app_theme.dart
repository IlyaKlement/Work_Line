import 'package:flutter/material.dart';

final Color primaryColor = Color(0xFFEFF1F3);

final ThemeData appTheme = ThemeData(
  scaffoldBackgroundColor: primaryColor,
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.light),
  useMaterial3: true,
);
