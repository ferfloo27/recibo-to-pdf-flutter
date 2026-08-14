// lib/main.dart
//
// Este es el punto de entrada de TODA app Flutter — `void main()` es lo
// primero que se ejecuta, igual que `main()` en Dart puro o en otros
// lenguajes. `runApp()` le dice a Flutter "toma este widget y píntalo en
// toda la pantalla".
//
// Por ahora este main.dart es TEMPORAL: solo sirve para probar el
// PdfService de forma aislada, sin depender todavía de Firebase, del
// formulario ni de go_router. Cuando lleguemos a la Tarea de navegación,
// vamos a reescribir este archivo para que arranque con go_router y
// las pantallas reales.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:printing/printing.dart';

import 'firebase_options.dart';
import 'services/pdf_service.dart';
import 'models/recibo_data.dart';
import 'ui/theme/app_theme.dart';

// `main()` ahora es `async` porque Firebase.initializeApp() es una
// operación asíncrona (se conecta al servidor de Firebase antes de poder
// usar Auth/Firestore/Storage). `WidgetsFlutterBinding.ensureInitialized()`
// es obligatorio ANTES de cualquier `await` en main() — le dice a Flutter
// "prepara el motor nativo" antes de que le pidamos hacer cosas async.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

/// El widget raíz de la app. Es un StatelessWidget porque este widget en sí
/// no tiene ningún dato que cambie con el tiempo — solo arma el MaterialApp
/// y le pasa el tema y la pantalla inicial.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReciboToPDF',
      theme: AppTheme.light, // Acá conectamos el tema que armamos antes.
      debugShowCheckedModeBanner: false,
      home: const PruebaPdfScreen(),
    );
  }
}

/// Pantalla temporal de prueba. SÍ es un StatefulWidget porque acá vamos a
/// tener un estado que cambia: si está generando el PDF o no (para mostrar
/// un loading y no dejar tocar el botón dos veces).
class PruebaPdfScreen extends StatefulWidget {
  const PruebaPdfScreen({super.key});

  @override
  State<PruebaPdfScreen> createState() => _PruebaPdfScreenState();
}

class _PruebaPdfScreenState extends State<PruebaPdfScreen> {
  // El servicio se crea una sola vez cuando se crea el State, no cada vez
  // que se repinta la pantalla (por eso está acá arriba, no dentro de build).
  final _pdfService = PdfService();

  bool _generando = false;

  Future<void> _generarYMostrarPdf() async {
    // setState() es la forma en que un StatefulWidget le dice a Flutter
    // "algo cambió, repinta la pantalla". Sin esto, aunque cambiemos la
    // variable _generando, la UI no se entera.
    setState(() => _generando = true);

    try {
      final data = ReciboData(
        numeroRecibo: '010/2024',
        monto: 40.0,
        montoEnTexto: 'Cuarenta 00/100 Bolivianos',
        recibiDe: 'Sección Logística',
        concepto: 'Pago de materiales de oficina',
        dia: 12,
        mes: 'Agosto',
        anio: 2026,
        cajero: 'Juan Pérez',
        comandante: 'Cnl. Carlos Gómez',
      );

      final bytes = await _pdfService.generarReciboPdf(data);

      // Printing.layoutPdf abre el visor nativo de PDF (o el de impresión)
      // con estos bytes. onLayout espera una función que DEVUELVA los
      // bytes — por eso el `async (_) async => bytes`.
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } finally {
      // El `finally` asegura que _generando vuelva a false pase lo que
      // pase (éxito o error), para que el botón no quede bloqueado.
      if (mounted) setState(() => _generando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba PdfService')),
      body: Center(
        child: ElevatedButton(
          // Mientras _generando es true, pasamos `null` como onPressed —
          // en Flutter, un botón con onPressed: null queda deshabilitado
          // automáticamente (se ve gris y no responde al toque).
          onPressed: _generando ? null : _generarYMostrarPdf,
          child: _generando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Generar PDF de prueba'),
        ),
      ),
    );
  }
}