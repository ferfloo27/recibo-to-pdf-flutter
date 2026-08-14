// lib/providers/service_providers.dart
//
// El provider más simple que existe en Riverpod: `Provider()` a secas.
// Solo expone UN valor fijo — acá, una instancia de cada service — para
// que cualquier otro provider o widget pueda pedirla con `ref.watch(...)`
// o `ref.read(...)` en vez de escribir `AuthService()` suelto por todos
// lados. Si mañana el AuthService necesitara un parámetro en su
// constructor, solo se cambia ACÁ, no en cada pantalla que lo usa.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/recibo_repository.dart';
import '../services/pdf_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final reciboRepositoryProvider =
    Provider<ReciboRepository>((ref) => ReciboRepository());

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());