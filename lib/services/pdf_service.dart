// lib/services/pdf_service.dart
//
// REESCRITO por completo para que coincida visualmente con la tarjeta de
// PreviewScreen (antes era un diseño distinto, "tipo documento oficial").
//
// DOS cambios técnicos importantes acá:
//
// 1. TAMAÑO DE PÁGINA: antes usábamos PdfPageFormat.letter (612 x 792 pt,
//    el tamaño completo de una hoja carta) — demasiado grande para un
//    recibo chico. Ahora usamos un tamaño personalizado: mismo ANCHO que
//    carta (612pt = 8.5 pulgadas), pero solo 288pt de alto (4 pulgadas).
//    Pediste "más o menos 1/3" — el tercio exacto de 792pt son 264pt, pero
//    con el diseño de tarjetas (con recuadros y espaciado) el contenido
//    queda MUY apretado ahí; 288pt (4 pulgadas, ~36% del alto de carta)
//    es el mínimo donde todo entra respirando bien. Si lo ves muy alto
//    igual, lo podemos ajustar más.
//
// 2. FUENTE: cargamos Roboto vía `PdfGoogleFonts` (viene incluido en el
//    paquete `printing`) en vez de dejar la fuente por defecto (Helvetica)
//    — esa es la fuente que no soporta bien acentos/símbolos como el "°",
//    y es la causa del warning "has no Unicode support" que viste en la
//    terminal.

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/recibo_data.dart';

class PdfService {
  static const _anchoPagina = 612.0; // 8.5 pulgadas — igual que carta.
  static const _altoPagina = 340.0; // 4 pulgadas (~1/3 de carta + margen de seguridad).

  Future<Uint8List> generarReciboPdf(ReciboData data) async {
    final document = pw.Document();

    // PdfGoogleFonts descarga (y cachea) la fuente la primera vez que se
    // usa en la sesión — por eso esto necesita `await` y conexión a
    // internet la primera vez.
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(_anchoPagina, _altoPagina, marginAll: 18),
        // `pw.ThemeData.withFont` aplica esta fuente a TODO el documento
        // por defecto — así no hay que especificar `font:` en cada
        // pw.Text suelto, solo en los casos donde querramos algo distinto
        // (como el itálico de "La cantidad de").
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold, italic: fontItalic),
        build: (context) => _buildContenido(data),
      ),
    );

    return document.save();
  }

  pw.Widget _buildContenido(ReciboData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEncabezado(data),
        pw.SizedBox(height: 8),
        _buildCampoDestacado('RECIBIMOS DE', data.nombreQuienRecibe),
        pw.SizedBox(height: 6),
        _buildCampoDestacado('LA CANTIDAD DE', data.montoEnTexto, cursiva: true),
        pw.SizedBox(height: 8),
        _buildTablaConcepto(data),
        pw.Spacer(),
        _buildFirmas(data),
      ],
    );
  }

  pw.Widget _buildEncabezado(ReciboData data) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            data.institucion.isEmpty ? '(Sin institución)' : data.institucion,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E3EBF7'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('RECIBO',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1565C0'))),
                  pw.Text('N° ${data.numeroRecibo}', style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text('Fecha: ${data.fechaCorta}', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCampoDestacado(String etiqueta, String valor, {bool cursiva = false}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F6F8'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(etiqueta,
              style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1565C0'))),
          pw.SizedBox(height: 2),
          pw.Text(
            valor.isEmpty ? '—' : valor,
            style: pw.TextStyle(
                fontSize: 9, fontStyle: cursiva ? pw.FontStyle.italic : pw.FontStyle.normal),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTablaConcepto(ReciboData data) {
    final montoFormateado = 'Bs ${data.monto.toStringAsFixed(2)}';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#D0D5DD'), width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const pw.BoxDecoration(color: PdfColor(0.92, 0.92, 0.94)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('POR CONCEPTO DE',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Text('IMPORTE',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.Text(data.concepto, style: const pw.TextStyle(fontSize: 9))),
                pw.Text(montoFormateado,
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
          pw.Divider(height: 1, color: PdfColor.fromHex('#D0D5DD')),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(montoFormateado,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1565C0'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFirmas(ReciboData data) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _bloqueFirma('FIRMA EMISOR', data.nombreQuienEntrega, data.cargoQuienEntrega),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: _bloqueFirma('FIRMA RECEPTOR', data.nombreQuienRecibe, data.cargoQuienRecibe),
        ),
      ],
    );
  }

  pw.Widget _bloqueFirma(String etiqueta, String nombre, String cargo) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.Text(nombre.isEmpty ? '—' : nombre, style: const pw.TextStyle(fontSize: 8)),
        if (cargo.trim().isNotEmpty)
          pw.Text(cargo, style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#666666'))),
        pw.SizedBox(height: 2),
        pw.Text(etiqueta, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}