// lib/ui/screens/preview_screen.dart
//
// REESTRUCTURADO siguiendo el mockup de Stitch: en vez de embeber un
// visor de PDF (PdfPreview), armamos una "tarjeta" con widgets normales
// de Flutter que replica visualmente el recibo. La generación del PDF
// real sigue exactamente igual por debajo (PdfService, guardado en
// Storage/Firestore) — lo único que cambió es qué se DIBUJA en pantalla
// mientras el usuario revisa los datos antes de guardar.
//
// Ventaja de este enfoque: se ve exactamente igual en Android y Web (son
// los mismos widgets de Flutter en ambos), sin depender de cómo cada
// plataforma renderiza un PDF.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../providers/pdf_preview_provider.dart';
import '../../providers/recibo_form_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/recibo_data.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _guardando = false;

  Future<void> _guardar() async {
    final bytes = ref.read(pdfPreviewBytesProvider);
    final userId = ref.read(currentUserIdProvider);
    if (bytes == null || userId == null) return;

    setState(() => _guardando = true);
    try {
      final data = ref.read(reciboFormProvider);
      final repository = ref.read(reciboRepositoryProvider);

      await repository.guardarRecibo(userId: userId, datos: data, pdfBytes: bytes);

      ref.read(reciboFormProvider.notifier).reiniciar();
      ref.read(pdfPreviewBytesProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recibo guardado correctamente')),
        );
        context.go('/history');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el recibo. Intente nuevamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _compartir() async {
    final bytes = ref.read(pdfPreviewBytesProvider);
    if (bytes == null) return;

    final numeroRecibo = ref.read(reciboFormProvider).numeroRecibo;
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recibo_${numeroRecibo.replaceAll('/', '-')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = ref.watch(pdfPreviewBytesProvider);
    final data = ref.watch(reciboFormProvider);

    if (bytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vista Previa')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No hay ningún PDF para mostrar.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/form'),
                child: const Text('Volver al formulario'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vista Previa')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: _TarjetaRecibo(data: data),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _guardando ? null : _compartir,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir / Descargar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _guardar,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta que replica el mockup. Widget separado (y sin estado propio)
/// porque solo depende de `data` — no necesita saber nada de Firebase ni
/// de los botones de abajo.
class _TarjetaRecibo extends StatelessWidget {
  final ReciboData data;
  const _TarjetaRecibo({required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final montoFormateado =
        NumberFormat.currency(locale: 'es_BO', symbol: 'Bs ', decimalDigits: 2)
            .format(data.monto);
    final fechaCorta = DateFormat("d MMMM yyyy", 'es').format(data.fecha);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Encabezado: institución a la izquierda, badge "RECIBO" +
            // número + fecha a la derecha.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data.institucion.isEmpty ? '(Sin institución)' : data.institucion,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('RECIBO',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          Text('N° ${data.numeroRecibo}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Fecha: $fechaCorta', style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            _campoDestacado(context, 'RECIBIMOS DE', data.nombreQuienRecibe),
            const SizedBox(height: 12),
            _campoDestacado(context, 'LA CANTIDAD DE', data.montoEnTexto, cursiva: true),
            const SizedBox(height: 16),

            // --- "Tabla" simplificada a una sola fila, ya que el modelo
            // maneja un único concepto/monto (no una lista de ítems).
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                            child: Text('POR CONCEPTO DE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                        Text('IMPORTE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(data.concepto)),
                        Text(montoFormateado, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          montoFormateado,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // --- Firmas: la misma lógica de cargo opcional que usamos en
            // el PDF real (PdfService) — si no hay cargo, no mostramos esa
            // línea extra.
            Row(
              children: [
                Expanded(
                  child: _bloqueFirma('FIRMA EMISOR', data.nombreQuienEntrega, data.cargoQuienEntrega),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _bloqueFirma('FIRMA RECEPTOR', data.nombreQuienRecibe, data.cargoQuienRecibe),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoDestacado(BuildContext context, String etiqueta, String valor,
      {bool cursiva = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          const SizedBox(height: 4),
          Text(
            valor.isEmpty ? '—' : valor,
            style: TextStyle(fontStyle: cursiva ? FontStyle.italic : FontStyle.normal),
          ),
        ],
      ),
    );
  }

  Widget _bloqueFirma(String etiqueta, String nombre, String cargo) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Divider(),
        Text(nombre.isEmpty ? '—' : nombre, style: const TextStyle(fontSize: 12)),
        if (cargo.trim().isNotEmpty)
          Text(cargo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(etiqueta, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}