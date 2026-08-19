// lib/providers/router_provider.dart
//
// ACTUALIZADO: ahora hay TRES estados posibles, no dos — sin sesión, con
// sesión pero SIN verificar el correo, y con sesión Y verificado. El
// `redirect` de abajo maneja los tres.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_provider.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/verify_email_screen.dart';
import '../ui/screens/form_screen.dart';
import '../ui/screens/preview_screen.dart';
import '../ui/screens/history_screen.dart';
import '../ui/screens/main_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/form',
    redirect: (context, state) {
      final usuario = authState.value;
      final haySesion = usuario != null;
      final correoVerificado = usuario?.emailVerified ?? false;

      final vaHaciaLogin = state.matchedLocation == '/login';
      final vaHaciaVerificar = state.matchedLocation == '/verify-email';

      if (!haySesion) {
        return vaHaciaLogin ? null : '/login';
      }

      if (!correoVerificado) {
        // Con sesión pero SIN verificar: solo se permite estar en
        // /verify-email. Ni siquiera /login tiene sentido acá (ya está
        // logueado), así que también redirige.
        return vaHaciaVerificar ? null : '/verify-email';
      }

      // Con sesión Y verificado: si intenta quedarse en /login o
      // /verify-email (ya no tienen sentido), lo mandamos al formulario.
      if (vaHaciaLogin || vaHaciaVerificar) return '/form';

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/verify-email', builder: (context, state) => const VerifyEmailScreen()),
      GoRoute(path: '/preview', builder: (context, state) => const PreviewScreen()),
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