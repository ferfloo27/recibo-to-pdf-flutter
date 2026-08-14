// lib/ui/screens/preview_screen.dart
//
// El widget `PdfPreview` del paquete `printing` hace todo el trabajo pesado
// de mostrar el PDF: paginación, zoom, scroll — nosotros solo le pasamos
// los bytes. Es el mismo paquete que usamos antes con `Printing.layoutPdf`,
// pero acá en vez de abrir un visor del sistema, lo incrustamos como un
// widget más dentro de nuestra propia pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import '../../providers/pdf_preview_provider.dart';
import '../../providers/recibo_form_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_providers.dart';

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
    if (bytes == null || userId == null) return; // No debería pasar; guard de seguridad.

    setState(() => _guardando = true);
    try {
      final data = ref.read(reciboFormProvider);
      final repository = ref.read(reciboRepositoryProvider);

      await repository.guardarRecibo(userId: userId, datos: data, pdfBytes: bytes);

      // Recibo guardado con éxito: ahora sí limpiamos el formulario y el
      // PDF en memoria (Requisito 4.7), porque ya cumplieron su propósito.
      ref.read(reciboFormProvider.notifier).reiniciar();
      ref.read(pdfPreviewBytesProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recibo guardado correctamente')),
        );
        // go (no push) porque no tiene sentido que el usuario pueda volver
        // "atrás" a una vista previa de un recibo que ya se guardó.
        context.go('/history');
      }
    } catch (e) {
      // Requisito 4.5: mostramos el error y CONSERVAMOS el PDF (no lo
      // borramos del provider) para que el usuario pueda tocar "Guardar"
      // de nuevo sin tener que rehacer el formulario.
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
    // Printing.sharePdf funciona igual en Android (abre el sheet nativo de
    // compartir) y en Web (dispara la descarga del archivo en el navegador)
    // — es la misma API para ambas plataformas, sin código condicional.
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'recibo_${numeroRecibo.replaceAll('/', '-')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = ref.watch(pdfPreviewBytesProvider);

    // Caso borde: si el usuario refrescó la página en Web estando en
    // /preview, el provider volvió a su estado inicial (null) y no hay
    // PDF que mostrar. En vez de crashear, lo mandamos de vuelta al
    // formulario con una explicación.
    if (bytes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vista previa')),
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
      appBar: AppBar(title: const Text('Vista previa')),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => bytes,
              // Ocultamos los botones propios de PdfPreview (imprimir,
              // compartir, etc.) porque ya ponemos los nuestros abajo,
              // conectados a nuestra lógica de Firebase.
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              actions: const [],
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