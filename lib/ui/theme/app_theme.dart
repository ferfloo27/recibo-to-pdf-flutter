// lib/ui/theme/app_theme.dart
//
// ¿Qué es Material 3? Es la versión más reciente del sistema de diseño de
// Google (colores dinámicos, formas más redondeadas, nueva tipografía). Lo
// activamos con `useMaterial3: true` en el ThemeData. Lo usamos como tema
// base "neutro" institucional: nada llamativo, apto para un documento oficial.
//
// ¿Por qué un ColorScheme.fromSeed()? En vez de definir manualmente 20+
// colores (primary, onPrimary, primaryContainer, error, onError...), le damos
// un solo color "semilla" y Material genera automáticamente una paleta
// armónica y con buen contraste (accesibilidad) a partir de él.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: true,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
