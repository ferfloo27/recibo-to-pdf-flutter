// lib/services/pdf_service.dart
//
// ¿Cómo funciona el paquete `pdf`? Se parece mucho a construir widgets de
// Flutter: en vez de Text/Column/Row de Flutter, usamos pw.Text/pw.Column/
// pw.Row (el prefijo "pw" = "package:pdf/widgets"). La diferencia es que
// esto NO se dibuja en pantalla, se "dibuja" dentro de un documento PDF.
//
// El flujo general siempre es:
//   1. Crear un pw.Document()
//   2. Agregarle una o más pw.Page con addPage()
//   3. Pedirle los bytes finales con document.save()
//
// Esos bytes son los que luego usamos con el paquete `printing` para
// mostrar la previsualización, compartir o guardar el archivo.

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/recibo_data.dart';

class PdfService {
  /// Construye el PDF del recibo y devuelve sus bytes en memoria.
  /// No lo guarda en ningún lado todavía — eso lo hace el FirebaseService
  /// más adelante, subiendo estos bytes a Storage.
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

  /// Todo el contenido visual del recibo, de arriba hacia abajo.
  /// Lo separamos en un método aparte (en vez de meterlo todo dentro del
  /// `build:` de arriba) porque así queda más fácil de leer: cada método
  /// `_buildX` es una "sección" del recibo.
  pw.Widget _buildContenido(ReciboData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEncabezadoConMonto(data),
        pw.SizedBox(height: 24),
        _buildTitulo(data),
        pw.SizedBox(height: 20),
        _buildRecibiDe(data),
        pw.SizedBox(height: 12),
        _buildLaSuma(data),
        pw.SizedBox(height: 12),
        _buildConcepto(data),
        pw.SizedBox(height: 30),
        _buildFecha(data),
        pw.Spacer(), // Empuja las firmas hasta abajo de la página.
        _buildFirmas(data),
      ],
    );
  }

  /// Encabezado institucional a la izquierda + caja del monto arriba a la
  /// derecha. Usamos un pw.Row porque necesitamos DOS cosas alineadas en
  /// extremos opuestos del mismo renglón horizontal.
  pw.Widget _buildEncabezadoConMonto(ReciboData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('FUERZA AÉREA BOLIVIANA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('ESC. DE PERFEC. TÉCNICO AERONÁUTICO',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Text('BOLIVIA', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        // La "caja" del monto: un pw.Container con `decoration` de borde,
        // igual que un Container con BoxDecoration en Flutter normal.
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
          ),
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

  /// "RECIBO" centrado con espaciado de letras (letter-spacing), y el
  /// número de recibo alineado a la derecha justo debajo.
  ///
  /// El paquete `pdf` no tiene una propiedad directa de "letterSpacing"
  /// como Flutter. El truco estándar es insertar espacios entre cada letra
  /// del texto (R E C I B O) — funciona bien para un título corto como este.
  pw.Widget _buildTitulo(ReciboData data) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'R E C I B O',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('N° ${data.numeroRecibo}',
              style: const pw.TextStyle(fontSize: 11)),
        ),
      ],
    );
  }

  /// Línea "Recibí de: ..." con puntos suspensivos hasta el borde.
  /// Reutilizamos _buildLineaConPuntos para no repetir el mismo patrón
  /// de layout dos veces (acá y en "La suma de").
  pw.Widget _buildRecibiDe(ReciboData data) {
    return _buildLineaConPuntos('Recibí de:', data.recibiDe);
  }

  pw.Widget _buildLaSuma(ReciboData data) {
    return _buildLineaConPuntos('La suma de:', data.montoEnTexto);
  }

  /// Genera una línea tipo "Etiqueta: ..........texto..........."
  /// usando un pw.Row con un Expanded en el medio para que los puntos
  /// rellenen automáticamente el espacio disponible, sin importar cuán
  /// largo sea el texto de la etiqueta o el valor.
  pw.Widget _buildLineaConPuntos(String etiqueta, String valor) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 11)),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            ' $valor ${'.' * 60}', // Rellenamos con puntos; al ser texto
            // dentro de un Expanded con overflow, el pdf lo recorta si no
            // entra, así que no se desborda de la página.
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  /// Campo de concepto: le damos más espacio vertical porque puede ser
  /// texto largo (es el único campo "libre" del formulario).
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

  /// Las dos columnas de firma. Usamos un pw.Row con dos Expanded para que
  /// ocupen el mismo ancho cada una, sin importar el largo de los nombres.
  pw.Widget _buildFirmas(ReciboData data) {
    return pw.Row(
      children: [
        pw.Expanded(child: _buildBloqueFirma('ENTREGUE CONFORME', data.cajero, 'CAJERO EPTA')),
        pw.SizedBox(width: 20),
        pw.Expanded(
            child: _buildBloqueFirma(
                'RECIBÍ CONFORME', data.comandante, 'COMANDANTE DE LA EPTA.')),
      ],
    );
  }

  /// Un bloque de firma individual: línea para firmar, nombre y cargo.
  /// pw.Divider dibuja la "línea" sobre la que se firmaría a mano.
  pw.Widget _buildBloqueFirma(String etiquetaSuperior, String nombre, String cargo) {
    return pw.Column(
      children: [
        pw.Text(etiquetaSuperior,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 30),
        pw.Divider(thickness: 0.5),
        pw.Text(nombre, style: const pw.TextStyle(fontSize: 10)),
        pw.Text(cargo, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }
}
