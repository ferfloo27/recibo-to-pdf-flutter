// lib/services/auth_service.dart
//
// ¿Por qué "envolver" FirebaseAuth en nuestra propia clase, en vez de usar
// FirebaseAuth.instance directo desde la UI? Dos razones:
//   1. Si mañana cambiamos de proveedor de auth, solo tocamos ESTE archivo,
//      no cada pantalla que hace login.
//   2. Traducimos los códigos de error crípticos de Firebase
//      ("auth/email-already-in-use") a mensajes en español que el usuario
//      entiende, en un solo lugar.

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Un Stream que emite un evento cada vez que cambia el estado de sesión
  /// (login, logout, o token expirado). La UI se "suscribe" a esto para
  /// saber en todo momento si mostrar la pantalla de login o la app.
  /// Emite `null` cuando no hay usuario logueado, o el User cuando sí.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  Future<void> registrar({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mensajeDeError(e);
    }
  }

  Future<void> iniciarSesion({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mensajeDeError(e);
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Traduce los códigos de error de Firebase a mensajes legibles.
  /// Lanzamos un String simple (no una excepción custom) porque la UI solo
  /// necesita mostrar el texto en un SnackBar — no necesita más estructura.
  String _mensajeDeError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'El correo electrónico ya está en uso';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        // Firebase distingue "usuario no existe" de "contraseña incorrecta",
        // pero por seguridad NO le decimos al usuario cuál de las dos falló
        // (si no, alguien podría usar la app para adivinar qué emails están
        // registrados probando uno por uno).
        return 'Correo o contraseña incorrectos';
      default:
        return 'Ocurrió un error de autenticación. Intenta de nuevo.';
    }
  }
}