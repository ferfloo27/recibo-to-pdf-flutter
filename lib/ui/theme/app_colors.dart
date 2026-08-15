// lib/ui/theme/app_colors.dart
//
// Centralizamos los colores acá en vez de escribirlos sueltos por toda la
// app (ej. Color(0xFF1B3A57) repetido en 5 pantallas). Así, si mañana quieren
// cambiar el color institucional, se edita en un solo lugar.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Constructor privado: esta clase nunca se instancia,
  // solo se usa como "namespace" para agrupar constantes (AppColors.primary).

  static const Color primary = Color(0xFF1565C0); // Azul Material más brillante (ajustado según mockup de Stitch)
  static const Color secondary = Color(0xFF7A8B99);
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFB3261E);
  static const Color onPrimary = Colors.white;
}