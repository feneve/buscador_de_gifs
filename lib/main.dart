import 'package:buscador_de_gifs/ui/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BuscadorDeGifsApp());
}

class BuscadorDeGifsApp extends StatelessWidget {
  const BuscadorDeGifsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00E5A0),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Buscador de GIFs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIconColor: Colors.white70,
          suffixIconColor: Colors.white70,
          border: _inputBorder(Colors.white24),
          enabledBorder: _inputBorder(Colors.white24),
          focusedBorder: _inputBorder(colorScheme.primary),
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const HomePage(),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }
}
