// lib/providers/recibo_form_provider.dart
//
// Mismo patrón de siempre (StateNotifier + copyWith), actualizado con los
// nuevos campos del modelo genérico.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recibo_data.dart';

class ReciboFormNotifier extends StateNotifier<ReciboData> {
  ReciboFormNotifier() : super(ReciboData.empty());

  void actualizarInstitucion(String value) =>
      state = state.copyWith(institucion: value);

  void actualizarNumeroRecibo(String value) =>
      state = state.copyWith(numeroRecibo: value);

  void actualizarFecha(DateTime value) => state = state.copyWith(fecha: value);

  void actualizarMonto(double value) => state = state.copyWith(monto: value);

  void actualizarMontoEnTexto(String value) =>
      state = state.copyWith(montoEnTexto: value);

  void actualizarConcepto(String value) =>
      state = state.copyWith(concepto: value);

  void actualizarNombreQuienEntrega(String value) =>
      state = state.copyWith(nombreQuienEntrega: value);

  void actualizarCargoQuienEntrega(String value) =>
      state = state.copyWith(cargoQuienEntrega: value);

  void actualizarNombreQuienRecibe(String value) =>
      state = state.copyWith(nombreQuienRecibe: value);

  void actualizarCargoQuienRecibe(String value) =>
      state = state.copyWith(cargoQuienRecibe: value);

  void reiniciar() => state = ReciboData.empty();
}

final reciboFormProvider =
    StateNotifierProvider<ReciboFormNotifier, ReciboData>(
  (ref) => ReciboFormNotifier(),
);