// lib/providers/router_provider.dart
//
// El corazón de la navegación protegida está en `redirect:`. go_router
// llama a esta función ANTES de mostrar cualquier pantalla, y le
// preguntamos: "¿a dónde debería ir realmente el usuario?". Devolver
// `null` significa "a ningún lado, deja que vaya a donde iba".
//
// Como este provider hace `ref.watch(authStateChangesProvider)`, cada vez
// que cambia la sesión (login/logout), Riverpod reconstruye el GoRouter
// completo con la nueva lógica de redirect — así, el simple hecho de
// loguearte dispara automáticamente la navegación a FormScreen, sin que
// LoginScreen tenga que llamar a un `context.go(...)` manualmente.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/form_screen.dart';
import '../ui/screens/preview_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/screens/main_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/form',
    redirect: (context, state) {
      // `authState.value` es null mientras el stream todavía no emitió su
      // primer evento (arranque de la app) O cuando no hay usuario
      // logueado — tratamos ambos casos igual: "no hay sesión confirmada
      // todavía, mándalo a login".
      final haySesion = authState.value != null;
      final vaHaciaLogin = state.matchedLocation == '/login';

      if (!haySesion) {
        // Sin sesión: solo se permite estar en /login. Cualquier otra
        // ruta redirige ahí (Requisito 6.2).
        return vaHaciaLogin ? null : '/login';
      }

      // Con sesión: si intenta quedarse en /login (ya no tiene sentido,
      // ya está logueado), lo mandamos al formulario.
      if (vaHaciaLogin) return '/form';

      return null; // Cualquier otro caso: no redirigir, dejar pasar.
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // PreviewScreen vive FUERA del shell (sin bottom nav) porque es un
      // paso intermedio del flujo de "crear un recibo", no una sección
      // principal de la app a la que quieras volver directo.
      GoRoute(path: '/preview', builder: (context, state) => const PreviewScreen()),

      // StatefulShellRoute.indexedStack mantiene el ESTADO de cada pestaña
      // vivo aunque cambies de una a otra (por ejemplo, si scrolleaste el
      // historial y volvés, sigue en la misma posición del scroll).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/form', builder: (context, state) => const FormScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          ]),
        ],
      ),
    ],
  );
});