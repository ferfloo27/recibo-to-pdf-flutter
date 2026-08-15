// lib/ui/screens/login_screen.dart
//
// Rediseñado siguiendo el mockup de Stitch: ícono circular de marca, toggle
// tipo "pastilla" arriba (en vez del link de abajo), campos con íconos, todo
// dentro de una Card centrada, y un link real de "olvidé mi contraseña".
//
// `ConsumerStatefulWidget` es la versión de Riverpod de un StatefulWidget
// normal: la necesitamos porque esta pantalla tiene DOS tipos de estado
// mezclados:
//   1. Estado LOCAL de la pantalla (¿está en modo login o registro?,
//      ¿está cargando?, los controllers de los TextField).
//   2. Estado GLOBAL vía Riverpod (el authServiceProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _modoRegistro = false;
  bool _cargando = false;
  bool _passwordVisible = false;
  bool _confirmarPasswordVisible = false;

  static final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_modoRegistro) {
        await authService.registrar(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authService.iniciarSesion(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } catch (mensajeError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Nuevo: "¿Olvidó su contraseña?" del mockup, conectado de verdad.
  /// Pide el email por un diálogo simple, y usa el método que agregamos
  /// a AuthService (Firebase se encarga de mandar el correo y de la
  /// página donde el usuario elige su nueva contraseña — nosotros no
  /// construimos nada de eso, es 100% manejado por Firebase).
  Future<void> _recuperarContrasena() async {
    final emailController = TextEditingController(text: _emailController.text);

    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo electrónico'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    try {
      await ref.read(authServiceProvider).enviarCorreoRecuperacion(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un correo para restablecer tu contraseña')),
        );
      }
    } catch (mensajeError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Cabecera de marca (ícono + título + subtítulo), FUERA
                // de la Card, igual que en el mockup.
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.description_outlined,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'ReciboToPDF',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Gestión documental profesional',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colorScheme.primary),
                ),
                const SizedBox(height: 24),

                // --- La Card blanca que contiene el toggle y el formulario.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ToggleLoginRegistro(
                            modoRegistro: _modoRegistro,
                            habilitado: !_cargando,
                            onChanged: (nuevoModo) =>
                                setState(() => _modoRegistro = nuevoModo),
                          ),
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electrónico',
                              hintText: 'usuario@empresa.com',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu correo electrónico';
                              }
                              if (!_emailRegex.hasMatch(value.trim())) {
                                return 'El correo electrónico no es válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_passwordVisible,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_passwordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () =>
                                    setState(() => _passwordVisible = !_passwordVisible),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),

                          if (_modoRegistro) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmarPasswordController,
                              obscureText: !_confirmarPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Confirmar contraseña',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_confirmarPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility),
                                  onPressed: () => setState(() =>
                                      _confirmarPasswordVisible = !_confirmarPasswordVisible),
                                ),
                              ),
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                            ),
                          ],

                          const SizedBox(height: 24),

                          FilledButton.icon(
                            onPressed: _cargando ? null : _enviar,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            icon: _cargando
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(
                              _modoRegistro ? 'Registrarme' : 'Ingresar al Sistema',
                            ),
                          ),

                          // Solo tiene sentido "olvidé mi contraseña" en
                          // modo login, no mientras se está registrando.
                          if (!_modoRegistro) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton(
                                onPressed: _cargando ? null : _recuperarContrasena,
                                child: const Text('¿Olvidó su contraseña?'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Pie de página, solo decorativo (como en el mockup).
                Text(
                  'Acceso Seguro  ·  Privacidad',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El toggle tipo "pastilla" del mockup (Iniciar Sesión / Registrarse).
/// Lo separamos en su propio widget porque es puramente visual y no
/// depende de nada de Firebase ni Riverpod — recibe el estado actual y un
/// callback, como cualquier widget "tonto" reutilizable.
class _ToggleLoginRegistro extends StatelessWidget {
  final bool modoRegistro;
  final bool habilitado;
  final ValueChanged<bool> onChanged;

  const _ToggleLoginRegistro({
    required this.modoRegistro,
    required this.habilitado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmento(
              context,
              texto: 'Iniciar Sesión',
              seleccionado: !modoRegistro,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _segmento(
              context,
              texto: 'Registrarse',
              seleccionado: modoRegistro,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmento(
    BuildContext context, {
    required String texto,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // AnimatedContainer anima solo el CAMBIO de color/forma cuando
    // `seleccionado` cambia — sin esto, el toggle "saltaría" de golpe en
    // vez de deslizarse suavemente.
    return GestureDetector(
      onTap: habilitado ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: seleccionado
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)]
              : null,
        ),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: seleccionado ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}