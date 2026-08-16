// lib/ui/screens/form_screen.dart
//
// Rediseñado siguiendo el mockup: secciones con título e ícono
// ("Información Básica", "Detalles del Monto", "Partes Involucradas"),
// cada una en su propia Card. El patrón de "cada campo empuja al
// provider" sigue igual que antes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/recibo_form_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/pdf_preview_provider.dart';
import '../../services/numero_a_texto_service.dart';

class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});

  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _generando = false;

  final _institucionController = TextEditingController();
  final _numeroReciboController = TextEditingController();
  final _montoController = TextEditingController();
  final _montoTextoController = TextEditingController();
  final _conceptoController = TextEditingController();
  final _nombreEntregaController = TextEditingController();
  final _cargoEntregaController = TextEditingController();
  final _nombreRecibeController = TextEditingController();
  final _cargoRecibeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // La fecha ya viene precargada con "hoy" desde ReciboData.empty(), pero
    // los demás controllers los sincronizamos por si el usuario vuelve
    // desde PreviewScreen con datos ya cargados (Requisito 6.4).
    final data = ref.read(reciboFormProvider);
    _institucionController.text = data.institucion;
    _numeroReciboController.text = data.numeroRecibo;
    if (data.monto > 0) _montoController.text = data.monto.toStringAsFixed(2);
    _montoTextoController.text = data.montoEnTexto;
    _conceptoController.text = data.concepto;
    _nombreEntregaController.text = data.nombreQuienEntrega;
    _cargoEntregaController.text = data.cargoQuienEntrega;
    _nombreRecibeController.text = data.nombreQuienRecibe;
    _cargoRecibeController.text = data.cargoQuienRecibe;
  }

  @override
  void dispose() {
    for (final c in [
      _institucionController,
      _numeroReciboController,
      _montoController,
      _montoTextoController,
      _conceptoController,
      _nombreEntregaController,
      _cargoEntregaController,
      _nombreRecibeController,
      _cargoRecibeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final fechaActual = ref.read(reciboFormProvider).fecha;
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: fechaActual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (nuevaFecha != null) {
      ref.read(reciboFormProvider.notifier).actualizarFecha(nuevaFecha);
    }
  }

  Future<void> _generarPdf() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _generando = true);
    try {
      final data = ref.read(reciboFormProvider);
      final pdfService = ref.read(pdfServiceProvider);
      final bytes = await pdfService.generarReciboPdf(data);

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
    final fechaActual = ref.watch(reciboFormProvider.select((d) => d.fecha));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _seccion(
              titulo: 'Información Básica',
              icono: Icons.info_outline,
              children: [
                TextFormField(
                  controller: _institucionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Institución',
                    hintText: 'Ej. Nombre de tu empresa u organización',
                  ),
                  validator: _requerido,
                  onChanged: (v) =>
                      ref.read(reciboFormProvider.notifier).actualizarInstitucion(v),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numeroReciboController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Recibo',
                          hintText: 'Ej. 0001',
                        ),
                        validator: _requerido,
                        onChanged: (v) => ref
                            .read(reciboFormProvider.notifier)
                            .actualizarNumeroRecibo(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      // No es un TextFormField normal — es un botón que
                      // ABRE el selector de fecha nativo (showDatePicker).
                      // InkWell + InputDecorator es el patrón estándar para
                      // que un campo "no editable a mano" se vea igual que
                      // los demás TextFormField del formulario.
                      child: InkWell(
                        onTap: _elegirFecha,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Fecha'),
                          child: Text(DateFormat('dd/MM/yyyy').format(fechaActual)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            _seccion(
              titulo: 'Detalles del Monto',
              icono: Icons.payments_outlined,
              children: [
                TextFormField(
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto', prefixText: 'Bs '),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa el monto';
                    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
                      return 'Formato inválido (ej. 40.00)';
                    }
                    return null;
                  },
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    if (parsed == null) return;

                    ref.read(reciboFormProvider.notifier).actualizarMonto(parsed);

                    // Cada vez que cambia el número, recalculamos el texto
                    // en letras y actualizamos el OTRO controller a mano
                    // (con .text =, no con setState) — como este campo ya
                    // no lo edita el usuario, no hace falta reconstruir
                    // toda la pantalla, solo actualizar lo que se ve en
                    // ese TextFormField puntual.
                    final textoGenerado = NumeroATextoService.convertir(parsed);
                    _montoTextoController.text = textoGenerado;
                    ref
                        .read(reciboFormProvider.notifier)
                        .actualizarMontoEnTexto(textoGenerado);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montoTextoController,
                  // readOnly (no `enabled: false`): la diferencia es que
                  // `enabled: false` además lo pinta gris y lo saca de la
                  // validación del Form. Queremos que SIGA participando
                  // del validator (por si el usuario intenta enviar sin
                  // haber puesto un monto todavía), solo que no se pueda
                  // tipear directo.
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Monto en texto (automático)',
                    hintText: 'Se completa solo al ingresar el monto',
                  ),
                  validator: _requerido,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _conceptoController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Concepto o Descripción'),
                  validator: _requerido,
                  onChanged: (v) =>
                      ref.read(reciboFormProvider.notifier).actualizarConcepto(v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _seccion(
              titulo: 'Partes Involucradas',
              icono: Icons.people_outline,
              children: [
                Text('Quien entrega', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nombreEntregaController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: _requerido,
                        onChanged: (v) => ref
                            .read(reciboFormProvider.notifier)
                            .actualizarNombreQuienEntrega(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cargoEntregaController,
                        decoration: const InputDecoration(labelText: 'Cargo (opcional)'),
                        // Sin validator: este campo es opcional, no hace
                        // falta que devuelva ningún error.
                        onChanged: (v) => ref
                            .read(reciboFormProvider.notifier)
                            .actualizarCargoQuienEntrega(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text('Quien recibe', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nombreRecibeController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: _requerido,
                        onChanged: (v) => ref
                            .read(reciboFormProvider.notifier)
                            .actualizarNombreQuienRecibe(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cargoRecibeController,
                        decoration: const InputDecoration(labelText: 'Cargo (opcional)'),
                        onChanged: (v) => ref
                            .read(reciboFormProvider.notifier)
                            .actualizarCargoQuienRecibe(v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _generando ? null : _generarPdf,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                icon: _generando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.visibility_outlined),
                label: const Text('Previsualizar Recibo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Cada "sección" del mockup: un título con ícono azul, dentro de una
  /// Card. La separamos en su propio método porque las 3 secciones
  /// comparten exactamente este mismo envoltorio visual.
  Widget _seccion({
    required String titulo,
    required IconData icono,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  String? _requerido(String? value) {
    if (value == null || value.trim().isEmpty) return 'Este campo es obligatorio';
    return null;
  }
}