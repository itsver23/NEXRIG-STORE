import 'package:flutter/material.dart';

const purple = Color(0xFF9D24FF);
const bg = Color(0xFF080916);
const panel = Color(0xFF16192B);

ThemeData get nexrigTheme => ThemeData.dark(useMaterial3: true).copyWith(
  scaffoldBackgroundColor: bg,
  colorScheme: const ColorScheme.dark(primary: purple, surface: panel),
  appBarTheme: const AppBarTheme(backgroundColor: bg),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: panel,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  ),
);
