// lib/services/pdf_service.dart
//
// REESTRUCTURADO: el encabezado ya no es texto fijo de la Fuerza Aérea —
// ahora viene del campo `institucion` que escribe el usuario. Las firmas
// ya no dicen "CAJERO EPTA" / "COMANDANTE DE LA EPTA" — dicen el nombre y,
// si lo cargaron, el cargo de cada persona (genérico para cualquier
// institución).

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/recibo_data.dart';

class PdfService {
  Future<Uint8List> generarReciboPdf(ReciboData data) async {
    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildContenido(data),
      ),
    );

    return document.save();
  }

  pw.Widget _buildContenido(ReciboData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEncabezadoConMonto(data),
        pw.SizedBox(height: 24),
        _buildTitulo(data),
        pw.SizedBox(height: 20),
        _buildQuienRecibe(data),
        pw.SizedBox(height: 12),
        _buildLaSuma(data),
        pw.SizedBox(height: 12),
        _buildConcepto(data),
        pw.SizedBox(height: 30),
        _buildFecha(data),
        pw.Spacer(),
        _buildFirmas(data),
      ],
    );
  }

  /// El encabezado ahora es simplemente el texto de `institucion` tal cual
  /// lo escribió el usuario — puede tener varias líneas (si tipeó saltos
  /// de línea), por eso lo separamos con `.split('\n')` y armamos un
  /// Text por línea, en vez de asumir 3 líneas fijas como antes.
  pw.Widget _buildEncabezadoConMonto(ReciboData data) {
    final lineasInstitucion = data.institucion.split('\n');

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lineasInstitucion.length; i++)
              pw.Text(
                lineasInstitucion[i],
                style: pw.TextStyle(
                  fontSize: i == 0 ? 12 : 10,
                  fontWeight: i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Column(
            children: [
              pw.Text('Bs', style: pw.TextStyle(fontSize: 9)),
              pw.Text(
                data.monto.toStringAsFixed(2),
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTitulo(ReciboData data) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text('R E C I B O',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('N° ${data.numeroRecibo}', style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  /// "Recibí de: [nombreQuienRecibe]" — usa el campo fusionado, como
  /// definimos: la misma persona que después firma a la derecha.
  pw.Widget _buildQuienRecibe(ReciboData data) {
    return _buildLineaConPuntos('Recibí de:', data.nombreQuienRecibe);
  }

  pw.Widget _buildLaSuma(ReciboData data) {
    return _buildLineaConPuntos('La suma de:', data.montoEnTexto);
  }

  pw.Widget _buildLineaConPuntos(String etiqueta, String valor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            ' $valor ${'.' * 60}',
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildConcepto(ReciboData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Concepto:', style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 6),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.Text(data.concepto, style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  pw.Widget _buildFecha(ReciboData data) {
    return pw.Center(
      child: pw.Text(data.fechaFormateada, style: const pw.TextStyle(fontSize: 11)),
    );
  }

  pw.Widget _buildFirmas(ReciboData data) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildBloqueFirma(
            etiquetaSuperior: 'ENTREGUE CONFORME',
            nombre: data.nombreQuienEntrega,
            cargo: data.cargoQuienEntrega,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: _buildBloqueFirma(
            etiquetaSuperior: 'RECIBÍ CONFORME',
            nombre: data.nombreQuienRecibe,
            cargo: data.cargoQuienRecibe,
          ),
        ),
      ],
    );
  }

  /// El cargo ahora es OPCIONAL: si vino vacío, simplemente no dibujamos
  /// esa línea (en vez de mostrar un espacio en blanco raro). El `if`
  /// dentro de la lista de children — igual que hicimos en Flutter normal —
  /// también es válido acá con los widgets `pw`.
  pw.Widget _buildBloqueFirma({
    required String etiquetaSuperior,
    required String nombre,
    required String cargo,
  }) {
    return pw.Column(
      children: [
        pw.Text(etiquetaSuperior,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 30),
        pw.Divider(thickness: 0.5),
        pw.Text(nombre, style: const pw.TextStyle(fontSize: 10)),
        if (cargo.trim().isNotEmpty)
          pw.Text(cargo, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }
}