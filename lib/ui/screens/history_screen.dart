// lib/ui/screens/history_screen.dart
//
// Sigue usando `historialProvider` (Stream de Firestore) como fuente de
// datos, igual que antes — lo nuevo es que ahora filtramos esa lista
// LOCALMENTE (en memoria, con Dart puro) según el texto de búsqueda y el
// chip seleccionado, en vez de hacer una query distinta a Firestore por
// cada filtro. Para el volumen de recibos que maneja un usuario individual
// (decenas, no millones), filtrar en el cliente es más simple y NO hace
// falta una query nueva cada vez que el usuario escribe una letra.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/historial_provider.dart';
import '../../models/recibo_guardado.dart';

enum _FiltroEstado { todos, completados, borradores, cancelados }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _busquedaController = TextEditingController();
  String _busqueda = '';
  _FiltroEstado _filtro = _FiltroEstado.todos;

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  /// Aplica el texto de búsqueda + el chip de estado sobre la lista
  /// completa que vino de Firestore.
  List<ReciboGuardado> _filtrar(List<ReciboGuardado> recibos) {
    // Requisito honesto: como todavía no existe un campo "estado" en
    // nuestros datos, un recibo guardado SIEMPRE se considera completado
    // (no hay forma de guardar uno "a medias" ni cancelarlo en el flujo
    // actual). Por eso "Borradores" y "Cancelados" devuelven vacío — no es
    // un bug, es honesto con lo que la app realmente soporta hoy.
    if (_filtro == _FiltroEstado.borradores || _filtro == _FiltroEstado.cancelados) {
      return [];
    }

    if (_busqueda.trim().isEmpty) return recibos;

    final query = _busqueda.trim().toLowerCase();
    return recibos.where((r) {
      final numero = r.datos.numeroRecibo.toLowerCase();
      final concepto = r.datos.concepto.toLowerCase();
      final monto = r.datos.monto.toStringAsFixed(2);
      return numero.contains(query) || concepto.contains(query) || monto.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historialAsync = ref.watch(historialProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de Recibos', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Consulta y administra los recibos emitidos anteriormente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _busquedaController,
            decoration: InputDecoration(
              hintText: 'Buscar por número, concepto o monto...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() => _busqueda = value),
          ),
          const SizedBox(height: 12),

          // SingleChildScrollView horizontal: si hay más chips de los que
          // entran en pantallas angostas, se pueden deslizar en vez de
          // partirse en varias líneas.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Todos', _FiltroEstado.todos),
                const SizedBox(width: 8),
                _chip('Completados', _FiltroEstado.completados),
                const SizedBox(width: 8),
                _chip('Borradores', _FiltroEstado.borradores),
                const SizedBox(width: 8),
                _chip('Cancelados', _FiltroEstado.cancelados),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: historialAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error al cargar el historial. Intente nuevamente.\n$error',
                    textAlign: TextAlign.center),
              ),
              data: (recibos) {
                final filtrados = _filtrar(recibos);

                if (recibos.isEmpty) {
                  return const Center(child: Text('No tienes recibos generados aún.'));
                }
                if (filtrados.isEmpty) {
                  return const Center(child: Text('Ningún recibo coincide con este filtro.'));
                }

                // Antes acá decidíamos entre GridView y ListView según el
                // ancho (con un LayoutBuilder). Lo sacamos: ese ancho no es
                // estable durante la animación del riel lateral en
                // MainShell, y cambiar de tipo de widget (GridView <->
                // ListView) a mitad de una animación de tamaño en curso es
                // justo lo que causaba los errores de "Assertion failed"
                // en sliver_multi_box_adaptor.dart.
                //
                // SliverGridDelegateWithMaxCrossAxisExtent YA se acomoda
                // solo a 1 columna cuando el espacio es angosto — así que
                // un solo GridView, siempre, nos da grilla en desktop Y
                // lista de una columna en celular, sin nunca cambiar de
                // tipo de widget.
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 138,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtrados.length,
                  itemBuilder: (context, i) => _ReciboCard(recibo: filtrados[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String texto, _FiltroEstado valor) {
    return ChoiceChip(
      label: Text(texto),
      selected: _filtro == valor,
      onSelected: (_) => setState(() => _filtro = valor),
    );
  }
}

class _ReciboCard extends StatelessWidget {
  final ReciboGuardado recibo;
  const _ReciboCard({required this.recibo});

  Future<void> _abrirPdf(BuildContext context) async {
    final uri = Uri.parse(recibo.storageUrl);
    final exito = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!exito && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final montoFormateado =
        NumberFormat.currency(locale: 'es_BO', symbol: '\$', decimalDigits: 2)
            .format(recibo.datos.monto);
    final fechaFormateada = DateFormat('dd MMM yyyy', 'es').format(recibo.creadoEn);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias, // Recorta el InkWell de abajo a las
      // esquinas redondeadas de la Card — sin esto, el efecto de "tocado"
      // se saldría del borde redondeado en las esquinas.
      child: InkWell(
        onTap: () => _abrirPdf(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // El "badge" gris con el número de recibo, como en el mockup.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recibo.datos.numeroRecibo,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                recibo.datos.concepto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fecha de emisión',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      Text(fechaFormateada, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}