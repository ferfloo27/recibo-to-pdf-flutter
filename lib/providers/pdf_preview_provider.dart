// lib/providers/pdf_preview_provider.dart
//
// ¿Por qué un provider para esto, en vez de pasar los bytes como argumento
// de navegación (context.go('/preview', extra: bytes))? Porque go_router
// pierde ese `extra` si el usuario refresca la página en Web (recarga
// desde cero, no hay "memoria" de la navegación anterior). Un provider en
// cambio sobrevive mientras la app esté abierta — más confiable para nuestro
// caso, aunque tampoco sobrevive un refresh (ver PreviewScreen: si llega
// vacío, volvemos a FormScreen).
//
// `StateProvider` es la versión más simple para un solo valor mutable desde
// afuera (a diferencia de StateNotifierProvider, no necesitamos métodos con
// nombre, solo `ref.read(provider.notifier).state = nuevoValor`).

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pdfPreviewBytesProvider = StateProvider<Uint8List?>((ref) => null);
