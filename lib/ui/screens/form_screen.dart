// lib/ui/screens/form_screen.dart
//
// Patrón que vamos a repetir en cada campo: el TextFormField no guarda su
// propio valor "de verdad" — cada vez que el usuario escribe, llamamos a un
// método del reciboFormProvider (ej. actualizarNumeroRecibo), que actualiza
// el ReciboData centralizado. Así, si el usuario va a PreviewScreen y
// vuelve (Requisito 6.4), los datos siguen ahí — porque no vivían en esta
// pantalla, vivían en el provider, que no se destruye al cambiar de pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/recibo_form_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/pdf_preview_provider.dart';

const _meses = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});

  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _generando = false;

  // Controllers solo para los campos de TEXTO libre. Los campos numéricos
  // de fecha (día, año) y el dropdown de mes los manejamos distinto, sin
  // controller, porque su valor sale directo del estado del provider.
  final _numeroReciboController = TextEditingController();
  final _montoController = TextEditingController();
  final _montoTextoController = TextEditingController();
  final _recibiDeController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _diaController = TextEditingController();
  final _anioController = TextEditingController();
  final _cajeroController = TextEditingController();
  final _comandanteController = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _numeroReciboController,
      _montoController,
      _montoTextoController,
      _recibiDeController,
      _conceptoController,
      _diaController,
      _anioController,
      _cajeroController,
      _comandanteController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generarPdf() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _generando = true);
    try {
      // En este punto el provider ya tiene el ReciboData completo y
      // actualizado, porque cada campo lo fue empujando con cada
      // onChanged — no necesitamos "juntar" los datos acá, solo leerlos.
      final data = ref.read(reciboFormProvider);
      final pdfService = ref.read(pdfServiceProvider);

      final bytes = await pdfService.generarReciboPdf(data);

      // Guardamos los bytes en el provider para que PreviewScreen los
      // encuentre, y navegamos.
      ref.read(pdfPreviewBytesProvider.notifier).state = bytes;

      if (mounted) context.push('/preview');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar el PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado fijo, NO editable — solo referencia visual
            // (Requisito 2.2). Un Container con fondo distinto lo deja
            // claro de un vistazo que no es un campo de formulario.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text('FUERZA AÉREA BOLIVIANA',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('ESC. DE PERFEC. TÉCNICO AERONÁUTICO'),
                  Text('BOLIVIA'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _numeroReciboController,
              decoration: const InputDecoration(labelText: 'Número de recibo (ej. 010/2024)'),
              validator: _requerido,
              onChanged: (v) =>
                  ref.read(reciboFormProvider.notifier).actualizarNumeroRecibo(v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monto en números (Bs)',
                prefixText: 'Bs ',
              ),
              // Requisito 2.5: formato decimal de hasta 2 decimales.
              // El regex `^\d+(\.\d{1,2})?$` acepta "40", "40.5" y "40.50",
              // pero rechaza letras o más de 2 decimales.
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Ingresa el monto';
                final regex = RegExp(r'^\d+(\.\d{1,2})?$');
                if (!regex.hasMatch(value.trim())) {
                  return 'Formato inválido (ej. 40.00)';
                }
                return null;
              },
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) {
                  ref.read(reciboFormProvider.notifier).actualizarMonto(parsed);
                }
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _montoTextoController,
              decoration: const InputDecoration(
                labelText: 'Monto en texto',
                hintText: 'Ej. Cuarenta 00/100 Bolivianos',
              ),
              validator: _requerido,
              onChanged: (v) =>
                  ref.read(reciboFormProvider.notifier).actualizarMontoEnTexto(v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _recibiDeController,
              decoration: const InputDecoration(labelText: 'Recibí de'),
              validator: _requerido,
              onChanged: (v) => ref.read(reciboFormProvider.notifier).actualizarRecibiDe(v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _conceptoController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Concepto'),
              validator: _requerido,
              onChanged: (v) => ref.read(reciboFormProvider.notifier).actualizarConcepto(v),
            ),
            const SizedBox(height: 12),

            // Fecha: tres campos en una fila (día / mes / año).
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _diaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Día'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 31) return 'Inválido';
                      return null;
                    },
                    onChanged: (_) => _actualizarFecha(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Mes'),
                    // El valor inicial es null; el usuario debe elegir uno
                    // explícitamente (evita un mes "por defecto" incorrecto
                    // que pase desapercibido).
                    value: null,
                    items: _meses
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    validator: (v) => v == null ? 'Elige un mes' : null,
                    onChanged: (v) {
                      if (v != null) _actualizarFecha(mesSeleccionado: v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _anioController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Año'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2000 || n > 2100) return 'Inválido';
                      return null;
                    },
                    onChanged: (_) => _actualizarFecha(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _cajeroController,
              decoration: const InputDecoration(labelText: 'Nombre del Cajero EPTA'),
              validator: _requerido,
              onChanged: (v) => ref.read(reciboFormProvider.notifier).actualizarCajero(v),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _comandanteController,
              decoration: const InputDecoration(labelText: 'Nombre del Comandante / Cnl.'),
              validator: _requerido,
              onChanged: (v) =>
                  ref.read(reciboFormProvider.notifier).actualizarComandante(v),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              // Requisito 2.7: deshabilitar mientras genera, para evitar
              // doble envío si el usuario toca el botón dos veces rápido.
              onPressed: _generando ? null : _generarPdf,
              child: _generando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Vista Previa'),
            ),
          ],
        ),
      ),
    );
  }

  /// Junta el día/mes/año actuales de los tres controles y actualiza el
  /// provider en una sola llamada, porque `actualizarFecha` en el
  /// StateNotifier pide los tres juntos (ver recibo_form_provider.dart).
  void _actualizarFecha({String? mesSeleccionado}) {
    final dia = int.tryParse(_diaController.text) ?? 0;
    final anio = int.tryParse(_anioController.text) ?? 0;
    final mesActual = mesSeleccionado ?? ref.read(reciboFormProvider).mes;

    ref.read(reciboFormProvider.notifier).actualizarFecha(
          dia: dia,
          mes: mesActual,
          anio: anio,
        );
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }
}