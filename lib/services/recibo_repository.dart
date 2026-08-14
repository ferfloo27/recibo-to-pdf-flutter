// lib/services/recibo_repository.dart
//
// Este archivo junta Firestore (metadatos) y Storage (el archivo PDF en sí)
// porque, conceptualmente, "guardar un recibo" es UNA sola operación desde
// el punto de vista de quien usa este repository — no queremos que la UI
// tenga que coordinar dos servicios distintos y acordarse del orden
// correcto (subir el archivo primero, luego escribir el documento).

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/recibo_data.dart';
import '../models/recibo_guardado.dart';

class ReciboRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube el PDF a Storage y luego crea el documento en Firestore con la
  /// URL resultante. Si algo falla en cualquiera de los dos pasos, la
  /// excepción sube tal cual hasta la UI, que decide cómo mostrarla
  /// (ver Requisito 4.5: mensaje de error + conservar el PDF para reintentar).
  Future<void> guardarRecibo({
    required String userId,
    required ReciboData datos,
    required Uint8List pdfBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nombreArchivo = '${timestamp}_${datos.numeroRecibo.replaceAll('/', '-')}.pdf';
    final ruta = 'recibos/$userId/$nombreArchivo';

    // Paso 1: subir el archivo. `putData` es la versión para bytes en
    // memoria (Uint8List) — a diferencia de `putFile`, que espera un
    // archivo en disco. Usamos putData porque en Web no siempre hay acceso
    // a un sistema de archivos real, así que trabajamos todo en memoria.
    final storageRef = _storage.ref(ruta);
    await storageRef.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    final url = await storageRef.getDownloadURL();

    // Paso 2: escribir el documento en Firestore, solo si el paso 1
    // funcionó. `FieldValue.serverTimestamp()` le pide al servidor de
    // Firebase que ponga LA HORA DEL SERVIDOR, no la del celular del
    // usuario — así, si alguien tiene el reloj mal configurado, el orden
    // del historial no se rompe.
    await _firestore.collection('recibos').add({
      'userId': userId,
      ...datos.toMap(),
      'storageUrl': url,
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  /// Stream con la lista de recibos del usuario, ordenados del más
  /// reciente al más antiguo (Requisito 5.2). Es un Stream (no un Future)
  /// porque así, si en el futuro guardas un recibo desde otra pestaña o
  /// dispositivo, el historial se actualiza solo, sin tener que refrescar
  /// manualmente.
  Stream<List<ReciboGuardado>> obtenerHistorial(String userId) {
    return _firestore
        .collection('recibos')
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_desdeDocumento).toList());
  }

  ReciboGuardado _desdeDocumento(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    final timestamp = map['creadoEn'] as Timestamp?;

    return ReciboGuardado(
      id: doc.id,
      datos: ReciboData.fromMap(map),
      storageUrl: map['storageUrl'] ?? '',
      // Si `creadoEn` todavía no llegó del servidor (puede pasar por un
      // instante justo después de escribir, por el modo offline-first de
      // Firestore), usamos la hora local como respaldo temporal.
      creadoEn: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}