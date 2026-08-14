// lib/providers/recibo_form_provider.dart
//
// `StateNotifier<T>` es para estado que CAMBIA con el tiempo por acciones
// del usuario (a diferencia de StreamProvider, que refleja algo externo
// como Firebase). Acá T es ReciboData: el formulario completo.
//
// El patrón es siempre igual: cada método público (actualizarNumeroRecibo,
// actualizarMonto, etc.) llama a `state = state.copyWith(...)`. Asignar a
// `state` es lo que dispara el repintado de la UI — por eso ReciboData es
// inmutable (visto en recibo_data.dart): NUNCA mutamos el objeto viejo,
// siempre creamos uno nuevo con copyWith y se lo asignamos a `state`.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recibo_data.dart';

class ReciboFormNotifier extends StateNotifier<ReciboData> {
  ReciboFormNotifier() : super(ReciboData.empty());

  void actualizarNumeroRecibo(String value) =>
      state = state.copyWith(numeroRecibo: value);

  void actualizarMonto(double value) => state = state.copyWith(monto: value);

  void actualizarMontoEnTexto(String value) =>
      state = state.copyWith(montoEnTexto: value);

  void actualizarRecibiDe(String value) =>
      state = state.copyWith(recibiDe: value);

  void actualizarConcepto(String value) =>
      state = state.copyWith(concepto: value);

  void actualizarFecha({required int dia, required String mes, required int anio}) =>
      state = state.copyWith(dia: dia, mes: mes, anio: anio);

  void actualizarCajero(String value) => state = state.copyWith(cajero: value);

  void actualizarComandante(String value) =>
      state = state.copyWith(comandante: value);

  /// Se llama después de guardar exitosamente en Firebase (Requisito 6.4:
  /// conservar los datos si el usuario vuelve atrás desde PreviewScreen,
  /// pero limpiar una vez que el recibo ya quedó guardado).
  void reiniciar() => state = ReciboData.empty();
}

/// `StateNotifierProvider` es el puente entre el StateNotifier de arriba y
/// los widgets. `ref.watch(reciboFormProvider)` da el ReciboData actual;
/// `ref.read(reciboFormProvider.notifier)` da la clase con los métodos
/// para modificarlo (el `.notifier` es la forma de "llamar acciones" sin
/// registrarse a los cambios de estado, que es lo que queremos al llamar
/// un método desde un onPressed).
final reciboFormProvider =
    StateNotifierProvider<ReciboFormNotifier, ReciboData>(
  (ref) => ReciboFormNotifier(),
);