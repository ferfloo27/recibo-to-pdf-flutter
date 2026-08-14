// lib/models/recibo_guardado.dart
//
// ¿Por qué no le agregamos estos campos directo a ReciboData? Porque
// ReciboData representa los datos del FORMULARIO (lo que el usuario
// escribe), y este representa un recibo que YA EXISTE en la nube, con
// información que solo tiene sentido después de guardarlo (id de Firestore,
// URL del PDF en Storage, fecha real de creación del servidor). Mezclar
// ambos conceptos en una sola clase generaría campos "a veces nulos, a
// veces no" — más difícil de razonar que dos clases separadas.

import 'recibo_data.dart';

class ReciboGuardado {
  final String id; // ID del documento en Firestore
  final ReciboData datos;
  final String storageUrl; // URL de descarga del PDF en Firebase Storage
  final DateTime creadoEn;

  const ReciboGuardado({
    required this.id,
    required this.datos,
    required this.storageUrl,
    required this.creadoEn,
  });
}