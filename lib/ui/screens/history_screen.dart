// lib/ui/screens/history_screen.dart
//
// `ref.watch(historialProvider)` devuelve un `AsyncValue<List<ReciboGuardado>>`
// — así es como Riverpod representa "un dato que viene de un Stream/Future y
// puede estar en 3 estados": cargando, con datos, o con error. El método
// `.when(...)` nos OBLIGA a manejar los tres casos, no hay forma de
// olvidarse de ninguno (a diferencia de un try/catch suelto, donde es fácil
// olvidarse del estado de loading).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/historial_provider.dart';
import '../../models/recibo_guardado.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialProvider);

    return historialAsync.when(
      // Requisito 5.6: loading en vez del listado.
      loading: () => const Center(child: CircularProgressIndicator()),

      // Requisito 5.7: mensaje de error si falla la carga.
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            const Text('Error al cargar el historial. Intente nuevamente.'),
          ],
        ),
      ),

      data: (recibos) {
        // Requisito 5.5: mensaje en vez de una lista vacía.
        if (recibos.isEmpty) {
          return const Center(child: Text('No tienes recibos generados aún.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: recibos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _ReciboTile(recibo: recibos[index]),
        );
      },
    );
  }
}

class _ReciboTile extends StatelessWidget {
  final ReciboGuardado recibo;

  const _ReciboTile({required this.recibo});

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
    // NumberFormat con locale 'es_BO' formatea el monto como "Bs 40,00" en
    // vez de "Bs 40.0" — más natural para un usuario boliviano.
    final montoFormateado =
        NumberFormat.currency(locale: 'es_BO', symbol: 'Bs ', decimalDigits: 2)
            .format(recibo.datos.monto);
    final fechaFormateada = DateFormat('dd/MM/yyyy').format(recibo.creadoEn);

    return Card(
      child: ListTile(
        leading: const Icon(Icons.receipt_long),
        title: Text('N° ${recibo.datos.numeroRecibo}'),
        subtitle: Text(
          '${recibo.datos.concepto}\n$fechaFormateada',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Text(
          montoFormateado,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => _abrirPdf(context),
      ),
    );
  }
}