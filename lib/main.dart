// lib/main.dart
//
// Este archivo ya no apunta a una pantalla fija — ahora `MyApp` es un
// `ConsumerWidget` (versión Riverpod de StatelessWidget que sí puede leer
// providers) y usa `MaterialApp.router` en vez de `MaterialApp` normal,
// que es la variante pensada para trabajar con go_router: en vez de un
// `home:` fijo, le pasamos `routerConfig:` con el GoRouter que arma
// router_provider.dart (login, formulario, historial, preview).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'ui/theme/app_theme.dart';
import 'providers/router_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // App Check verifica —por debajo, sin que la UI se entere— que cada
  // petición a Firestore/Storage/Auth venga de ESTA app compilada, no de
  // un script que copió las API keys y las usa directo contra el backend.
  // Cada plataforma usa un "proveedor" distinto:
  //   - Web: reCAPTCHA v3 (invisible, no le aparece ningún captcha al usuario)
  //   - Android: Play Integrity (verifica la firma de la app instalada)
  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider('6Lc5-YwtAAAAAO6L0k5Cyn4H89Xv8Q3DNQ1z54Xx'),
    androidProvider: AndroidProvider.playIntegrity,
  );
  await initializeDateFormatting('es');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch acá significa: si goRouterProvider se reconstruye (porque
    // cambió el estado de auth), MyApp entero se reconstruye con el router
    // actualizado — así es como el login/logout dispara la navegación sola.
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'ReciboToPDF',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}