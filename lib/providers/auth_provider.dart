// lib/providers/auth_provider.dart
//
// `StreamProvider` es un tipo especial de provider hecho para envolver un
// Stream (como el `authStateChanges` de nuestro AuthService). Riverpod se
// suscribe al stream por nosotros, y cada vez que emite un nuevo valor
// (login, logout), automáticamente le avisa a TODOS los widgets que estén
// "escuchando" este provider para que se repinten con el nuevo estado.
//
// Desde la UI, en vez de manejar StreamBuilder a mano en cada pantalla que
// necesita saber si hay sesión activa, simplemente hacemos:
//   final authState = ref.watch(authStateChangesProvider);
// y Riverpod se encarga del resto.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'service_providers.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Atajo muy usado: el ID del usuario actual, o null si no hay sesión.
/// Lo separamos en su propio provider porque MUCHOS otros providers (el
/// historial, por ejemplo) solo necesitan el uid, no el objeto User
/// completo — así evitamos que se recalculen de más si otro campo del
/// User cambia mientras el uid sigue siendo el mismo.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.value?.uid;
});