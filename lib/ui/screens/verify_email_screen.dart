// lib/ui/screens/verify_email_screen.dart
//
// El usuario cae acá cuando tiene sesión iniciada PERO su correo todavía
// no está verificado. No puede avanzar a ninguna otra pantalla hasta que
// lo verifique (eso lo hace el `redirect` de go_router, no esta pantalla).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _cargando = false;

  Future<void> _reenviar() async {
    setState(() => _cargando = true);
    try {
      await ref.read(authServiceProvider).reenviarVerificacion();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Correo reenviado')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _yaVerifique() async {
    setState(() => _cargando = true);
    // Le pedimos a Firebase el estado más actual del usuario. El
    // `authStateChangesProvider` (StreamProvider) no se entera solo de que
    // `emailVerified` cambió de `false` a `true` — por eso hace falta este
    // refresh explícito y forzar la reconstrucción del router, en vez de
    // esperar a que llegue un evento nuevo del stream.
    await ref.read(authServiceProvider).refrescarUsuario();
    // Invalidar el provider fuerza a Riverpod a "re-preguntarle" a
    // Firebase el estado actual (con el usuario ya refrescado), en vez de
    // seguir mostrando el valor viejo que tenía cacheado.
    ref.invalidate(authServiceProvider);
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _cerrarSesion() =>
      ref.read(authServiceProvider).cerrarSesion();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 56),
              const SizedBox(height: 16),
              Text('Verifica tu correo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Te enviamos un correo con un link de verificación. '
                'Ábrelo y luego vuelve acá.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _cargando ? null : _yaVerifique,
                child: const Text('Ya verifiqué mi correo'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _cargando ? null : _reenviar,
                child: const Text('Reenviar correo'),
              ),
              TextButton(
                onPressed: _cerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
