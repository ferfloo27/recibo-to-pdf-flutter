// lib/models/recibo_data.dart
//
// ¿Por qué es INMUTABLE (todos los campos `final`)? Riverpod (y el estado
// reactivo en general) funciona mejor cuando, en vez de "mutar" un objeto
// existente, creamos uno nuevo cada vez que algo cambia. Eso hace que:
//   1. Sea imposible que dos partes de la app modifiquen el mismo objeto
//      "por atrás" sin que nadie se entere.
//   2. Cada cambio de estado sea un objeto nuevo y comparable, lo que hace
//      más fácil debuggear ("¿por qué cambió la pantalla? -> llegó este
//      ReciboData nuevo").
//
// Por eso NO hay setters (`data.monto = 5`), sino `copyWith`, que devuelve
// una copia con solo los campos indicados cambiados.

class ReciboData {
  final String numeroRecibo; // Ej: "010/2024"
  final double monto; // Monto en números (Bolivianos)
  final String montoEnTexto; // Ej: "Cuarenta 00/100 Bolivianos"
  final String recibiDe; // Quién entrega el dinero
  final String concepto; // Motivo del pago
  final int dia;
  final String mes; // En texto: "Enero", "Febrero", ...
  final int anio;
  final String cajero; // Nombre del Cajero EPTA
  final String comandante; // Nombre del Comandante / Cnl.

  const ReciboData({
    required this.numeroRecibo,
    required this.monto,
    required this.montoEnTexto,
    required this.recibiDe,
    required this.concepto,
    required this.dia,
    required this.mes,
    required this.anio,
    required this.cajero,
    required this.comandante,
  });

  /// Estado inicial vacío, usado por el provider del formulario antes de
  /// que el usuario escriba nada.
  factory ReciboData.empty() => const ReciboData(
        numeroRecibo: '',
        monto: 0,
        montoEnTexto: '',
        recibiDe: '',
        concepto: '',
        dia: 0,
        mes: '',
        anio: 0,
        cajero: '',
        comandante: '',
      );

  /// Devuelve una copia de este ReciboData con los campos indicados
  /// reemplazados. Los campos que no se pasan mantienen su valor actual.
  /// Ej: `data.copyWith(monto: 40.0)` — todo igual, solo cambia el monto.
  ReciboData copyWith({
    String? numeroRecibo,
    double? monto,
    String? montoEnTexto,
    String? recibiDe,
    String? concepto,
    int? dia,
    String? mes,
    int? anio,
    String? cajero,
    String? comandante,
  }) {
    return ReciboData(
      numeroRecibo: numeroRecibo ?? this.numeroRecibo,
      monto: monto ?? this.monto,
      montoEnTexto: montoEnTexto ?? this.montoEnTexto,
      recibiDe: recibiDe ?? this.recibiDe,
      concepto: concepto ?? this.concepto,
      dia: dia ?? this.dia,
      mes: mes ?? this.mes,
      anio: anio ?? this.anio,
      cajero: cajero ?? this.cajero,
      comandante: comandante ?? this.comandante,
    );
  }

  /// Convierte el objeto a un Map plano — así es como Firestore guarda los
  /// documentos (Firestore no entiende clases de Dart, solo mapas/JSON).
  Map<String, dynamic> toMap() {
    return {
      'numeroRecibo': numeroRecibo,
      'monto': monto,
      'montoEnTexto': montoEnTexto,
      'recibiDe': recibiDe,
      'concepto': concepto,
      'dia': dia,
      'mes': mes,
      'anio': anio,
      'cajero': cajero,
      'comandante': comandante,
    };
  }

  /// El camino inverso: reconstruye un ReciboData a partir de lo que
  /// devuelve Firestore. Usamos valores por defecto (`?? ''`, `?? 0`) por si
  /// algún documento viejo no tiene un campo — así no explota la app.
  factory ReciboData.fromMap(Map<String, dynamic> map) {
    return ReciboData(
      numeroRecibo: map['numeroRecibo'] ?? '',
      monto: (map['monto'] ?? 0).toDouble(),
      montoEnTexto: map['montoEnTexto'] ?? '',
      recibiDe: map['recibiDe'] ?? '',
      concepto: map['concepto'] ?? '',
      dia: map['dia'] ?? 0,
      mes: map['mes'] ?? '',
      anio: map['anio'] ?? 0,
      cajero: map['cajero'] ?? '',
      comandante: map['comandante'] ?? '',
    );
  }

  /// "Fecha" ya formateada como el recibo la necesita en el PDF:
  /// "Cochabamba, 5 de Enero de 2026"
  String get fechaFormateada => 'Cochabamba, $dia de $mes de $anio';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReciboData &&
        other.numeroRecibo == numeroRecibo &&
        other.monto == monto &&
        other.montoEnTexto == montoEnTexto &&
        other.recibiDe == recibiDe &&
        other.concepto == concepto &&
        other.dia == dia &&
        other.mes == mes &&
        other.anio == anio &&
        other.cajero == cajero &&
        other.comandante == comandante;
  }

  @override
  int get hashCode => Object.hash(numeroRecibo, monto, montoEnTexto, recibiDe,
      concepto, dia, mes, anio, cajero, comandante);
}
