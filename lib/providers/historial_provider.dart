// lib/providers/historial_provider.dart
//
// `StreamProvider.autoDispose` — igual que el de auth, pero con
// `.autoDispose`: esto le dice a Riverpod "si ninguna pantalla está
// mirando este provider, deja de escuchar el Stream de Firestore y libera
// la memoria". Sin autoDispose, la suscripción quedaría viva para siempre
// aunque el usuario nunca vuelva a HistoryScreen — un desperdicio de
// lecturas de Firestore (que cuestan dinero, aunque sea poco).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recibo_guardado.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

final historialProvider = StreamProvider.autoDispose<List<ReciboGuardado>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final repository = ref.watch(reciboRepositoryProvider);

  // Si no hay usuario logueado (no debería pasar, porque esta pantalla
  // está protegida por el AuthGate, pero por robustez), devolvemos un
  // stream vacío en vez de crashear.
  if (userId == null) return const Stream.empty();

  return repository.obtenerHistorial(userId);
});