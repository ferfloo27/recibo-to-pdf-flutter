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
      creadoEn: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  /// Mira TODOS los números de recibo que ya tiene este usuario, saca el
  /// número más alto que encuentre (buscando dígitos dentro del texto,
  /// porque el campo es libre — puede ser "0007", "REC-2024-007", etc.) y
  /// sugiere el siguiente, con el mismo relleno de ceros a la izquierda.
  ///
  /// Como `numeroRecibo` es texto libre (no un contador real en la base),
  /// esto es una SUGERENCIA basada en lo que ya existe — no una garantía
  /// matemática de que sea único (por eso además tenemos
  /// `existeNumeroRecibo`, que si valida de verdad antes de guardar).
  Future<String> sugerirSiguienteNumero(String userId) async {
    final snapshot =
        await _firestore.collection('recibos').where('userId', isEqualTo: userId).get();

    var maximo = 0;
    var digitosDelMaximo = 4; // Por defecto, si no hay ningún recibo previo.

    for (final doc in snapshot.docs) {
      final numero = doc.data()['numeroRecibo'] as String? ?? '';
      // Busca TODAS las secuencias de dígitos dentro del texto y se queda
      // con la ÚLTIMA (ej. en "REC-2024-007" nos interesa el "007", no el
      // "2024") — es la parte que normalmente actúa como "correlativo".
      final coincidencias = RegExp(r'\d+').allMatches(numero).toList();
      if (coincidencias.isEmpty) continue;

      final texto = coincidencias.last.group(0)!;
      final valor = int.tryParse(texto) ?? 0;
      if (valor > maximo) {
        maximo = valor;
        digitosDelMaximo = texto.length;
      }
    }

    return (maximo + 1).toString().padLeft(digitosDelMaximo, '0');
  }

  /// Verificación real de duplicados. OJO: no compara el texto tal cual
  /// (eso fallaba con "002" vs "2" — mismo número, texto distinto) — en
  /// vez de eso, NORMALIZA cada número antes de comparar: si es puramente
  /// numérico, le sacamos los ceros a la izquierda (parseándolo como int);
  /// si tiene letras/guiones (ej. "REC-2024-007"), comparamos el texto tal
  /// cual, en minúsculas.
  ///
  /// Como esta normalización no se puede hacer del lado de Firestore (la
  /// base no sabe qué es "el mismo número" para nosotros), traemos TODOS
  /// los recibos del usuario y comparamos acá, en Dart. Para la cantidad
  /// de recibos que maneja una persona (decenas, no miles), esto es
  /// perfectamente rápido.
  Future<bool> existeNumeroRecibo(String userId, String numeroRecibo) async {
    final snapshot =
        await _firestore.collection('recibos').where('userId', isEqualTo: userId).get();

    final buscado = _normalizarNumero(numeroRecibo);

    return snapshot.docs.any((doc) {
      final existente = doc.data()['numeroRecibo'] as String? ?? '';
      return _normalizarNumero(existente) == buscado;
    });
  }

  String _normalizarNumero(String numero) {
    final limpio = numero.trim();
    if (RegExp(r'^\d+$').hasMatch(limpio)) {
      // "002" -> parseamos a 2 -> volvemos a texto -> "2". Así "002",
      // "02" y "2" quedan todos como "2" al comparar.
      return int.parse(limpio).toString();
    }
    return limpio.toLowerCase();
  }
}