// lib/models/recibo_data.dart
//
// REESTRUCTURADO para ser genérico (no atado a la Fuerza Aérea/EPTA):
//   - `institucion`: texto libre que reemplaza el encabezado fijo.
//   - `nombreQuienEntrega` / `cargoQuienEntrega`: firma izquierda. El cargo
//     es OPCIONAL (no toda persona que entrega tiene un puesto formal).
//   - `nombreQuienRecibe` / `cargoQuienRecibe`: aparece en "Recibí de:" Y
//     en la firma derecha — es la MISMA persona en los dos lugares, según
//     lo que definimos.
//   - `fecha` ahora es un DateTime real (antes eran 3 campos sueltos:
//     día/mes/año) — se puede formatear de cualquier forma con `intl`, y
//     se presta a un selector de fecha nativo en la UI.

import 'package:intl/intl.dart';

class ReciboData {
  final String institucion;
  final String numeroRecibo;
  final DateTime fecha;
  final double monto;
  final String montoEnTexto;
  final String concepto;
  final String nombreQuienEntrega;
  final String cargoQuienEntrega; // Puede quedar vacío — es opcional.
  final String nombreQuienRecibe;
  final String cargoQuienRecibe; // Puede quedar vacío — es opcional.

  const ReciboData({
    required this.institucion,
    required this.numeroRecibo,
    required this.fecha,
    required this.monto,
    required this.montoEnTexto,
    required this.concepto,
    required this.nombreQuienEntrega,
    required this.cargoQuienEntrega,
    required this.nombreQuienRecibe,
    required this.cargoQuienRecibe,
  });

  /// La fecha arranca en HOY (Requisito nuevo: precargar la fecha actual,
  /// el usuario la puede cambiar si quiere). El resto arranca vacío, como
  /// antes.
  factory ReciboData.empty() => ReciboData(
        institucion: '',
        numeroRecibo: '',
        fecha: DateTime.now(),
        monto: 0,
        montoEnTexto: '',
        concepto: '',
        nombreQuienEntrega: '',
        cargoQuienEntrega: '',
        nombreQuienRecibe: '',
        cargoQuienRecibe: '',
      );

  ReciboData copyWith({
    String? institucion,
    String? numeroRecibo,
    DateTime? fecha,
    double? monto,
    String? montoEnTexto,
    String? concepto,
    String? nombreQuienEntrega,
    String? cargoQuienEntrega,
    String? nombreQuienRecibe,
    String? cargoQuienRecibe,
  }) {
    return ReciboData(
      institucion: institucion ?? this.institucion,
      numeroRecibo: numeroRecibo ?? this.numeroRecibo,
      fecha: fecha ?? this.fecha,
      monto: monto ?? this.monto,
      montoEnTexto: montoEnTexto ?? this.montoEnTexto,
      concepto: concepto ?? this.concepto,
      nombreQuienEntrega: nombreQuienEntrega ?? this.nombreQuienEntrega,
      cargoQuienEntrega: cargoQuienEntrega ?? this.cargoQuienEntrega,
      nombreQuienRecibe: nombreQuienRecibe ?? this.nombreQuienRecibe,
      cargoQuienRecibe: cargoQuienRecibe ?? this.cargoQuienRecibe,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'institucion': institucion,
      'numeroRecibo': numeroRecibo,
      // Firestore no tiene un tipo "DateTime" propio — lo guardamos como
      // milisegundos desde 1970 (un entero), y lo reconstruimos con
      // DateTime.fromMillisecondsSinceEpoch al leerlo. Es el patrón
      // estándar para fechas "de dominio" (la fecha DEL recibo, distinta
      // de `creadoEn`, que sí usa el Timestamp del servidor).
      'fecha': fecha.millisecondsSinceEpoch,
      'monto': monto,
      'montoEnTexto': montoEnTexto,
      'concepto': concepto,
      'nombreQuienEntrega': nombreQuienEntrega,
      'cargoQuienEntrega': cargoQuienEntrega,
      'nombreQuienRecibe': nombreQuienRecibe,
      'cargoQuienRecibe': cargoQuienRecibe,
    };
  }

  factory ReciboData.fromMap(Map<String, dynamic> map) {
    final fechaMs = map['fecha'] as int?;
    return ReciboData(
      institucion: map['institucion'] ?? '',
      numeroRecibo: map['numeroRecibo'] ?? '',
      fecha: fechaMs != null
          ? DateTime.fromMillisecondsSinceEpoch(fechaMs)
          : DateTime.now(),
      monto: (map['monto'] ?? 0).toDouble(),
      montoEnTexto: map['montoEnTexto'] ?? '',
      concepto: map['concepto'] ?? '',
      nombreQuienEntrega: map['nombreQuienEntrega'] ?? '',
      cargoQuienEntrega: map['cargoQuienEntrega'] ?? '',
      nombreQuienRecibe: map['nombreQuienRecibe'] ?? '',
      cargoQuienRecibe: map['cargoQuienRecibe'] ?? '',
    );
  }

  /// "Cochabamba, 5 de enero de 2026" — para el cuerpo del PDF/vista previa.
  String get fechaFormateada =>
      'Cochabamba, ${DateFormat("d 'de' MMMM 'de' yyyy", 'es').format(fecha)}';

  /// "5 enero 2026" — versión corta, sin ciudad, para el badge de fecha.
  String get fechaCorta => DateFormat("d MMMM yyyy", 'es').format(fecha);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReciboData &&
        other.institucion == institucion &&
        other.numeroRecibo == numeroRecibo &&
        other.fecha == fecha &&
        other.monto == monto &&
        other.montoEnTexto == montoEnTexto &&
        other.concepto == concepto &&
        other.nombreQuienEntrega == nombreQuienEntrega &&
        other.cargoQuienEntrega == cargoQuienEntrega &&
        other.nombreQuienRecibe == nombreQuienRecibe &&
        other.cargoQuienRecibe == cargoQuienRecibe;
  }

  @override
  int get hashCode => Object.hash(
        institucion,
        numeroRecibo,
        fecha,
        monto,
        montoEnTexto,
        concepto,
        nombreQuienEntrega,
        cargoQuienEntrega,
        nombreQuienRecibe,
        cargoQuienRecibe,
      );
}