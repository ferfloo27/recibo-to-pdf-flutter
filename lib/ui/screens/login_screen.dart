// lib/ui/screens/login_screen.dart
//
// `ConsumerStatefulWidget` es la versión de Riverpod de un StatefulWidget
// normal: la necesitamos porque esta pantalla tiene DOS tipos de estado
// mezclados:
//   1. Estado LOCAL de la pantalla (¿está en modo login o registro?,
//      ¿está cargando?, los controllers de los TextField) — esto vive acá
//      mismo, no tiene sentido que sea un provider global.
//   2. Estado GLOBAL vía Riverpod (el authServiceProvider) — para eso
//      necesitamos el `ref` que solo un Consumer(Stateful)Widget expone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/service_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // GlobalKey<FormState> es cómo Flutter valida un formulario completo de
  // una sola vez (recorre todos los TextFormField y corre sus validators).
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  bool _modoRegistro = false;
  bool _cargando = false;

  @override
  void dispose() {
    // Los TextEditingController usan recursos nativos por debajo — hay
    // que liberarlos explícitamente cuando el widget se destruye, o se
    // "filtran" (memory leak). Flutter NO lo hace solo.
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    // validate() corre todos los `validator:` de los campos de abajo.
    // Si alguno devuelve un String (mensaje de error), validate() muestra
    // ese mensaje bajo el campo y devuelve false — ahí cortamos, sin
    // llamar a Firebase todavía (Requisito 1.5).
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
      // No navegamos manualmente a ningún lado acá: el authStateChangesProvider
      // (que armamos antes) va a detectar el cambio de sesión solo, y el
      // AuthGate/go_router (próxima tarea) se encarga de redirigir. Esta
      // pantalla no necesita saber "a dónde ir después de loguearse".
    } catch (mensajeError) {
      // AuthService lanza un String (no una excepción compleja), así que
      // acá `mensajeError` ya es el texto listo para mostrar al usuario.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            // Limitamos el ancho máximo: en Web, en una pantalla ancha de
            // escritorio, un formulario de login estirado de punta a punta
            // se ve mal. En Android esto no tiene efecto (el celular ya es
            // más angosto que 400px).
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ReciboToPDF',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modoRegistro ? 'Crea tu cuenta' : 'Inicia sesión',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    // El validator corre ANTES de tocar Firebase — es
                    // validación de formato, no de si el email existe.
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo electrónico';
                      }
                      if (!value.contains('@')) {
                        return 'El correo electrónico no es válido';
                      }
                      return null; // null = campo válido.
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),

                  // Este campo solo aparece en modo registro. `if` dentro
                  // de una lista de widgets es un truco válido de Dart: si
                  // la condición es falsa, ese widget simplemente no se
                  // agrega a la lista (no es "invisible", no existe).
                  if (_modoRegistro) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmarPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _cargando ? null : _enviar,
                    child: _cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_modoRegistro ? 'Registrarme' : 'Iniciar sesión'),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    // Alternar entre modo login/registro solo cambia estado
                    // LOCAL de esta pantalla — no toca Firebase para nada.
                    onPressed: _cargando
                        ? null
                        : () => setState(() => _modoRegistro = !_modoRegistro),
                    child: Text(
                      _modoRegistro
                          ? '¿Ya tienes cuenta? Inicia sesión'
                          : '¿No tienes cuenta? Regístrate',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}