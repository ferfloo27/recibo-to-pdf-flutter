# Implementation Plan: ReciboToPDF

## Overview

Implementación paso a paso de la aplicación Flutter multiplataforma para generar recibos institucionales PDF de la EPTA. Las tareas están ordenadas pedagógicamente: primero los fundamentos (estructura, modelos, tema), luego los servicios, después los providers de estado y finalmente las pantallas, conectando todo al final. Cada tarea construye sobre la anterior.

## Tasks

- [ ] 1. Configuración inicial del proyecto Flutter y Firebase
  - [ ] 1.1 Crear el proyecto Flutter con soporte web y Android
    - Ejecutar `flutter create recibo_to_pdf --platforms android,web` y verificar que compila en ambas plataformas.
    - Eliminar el código de ejemplo de `main.dart` y `test/widget_test.dart`.
    - Agregar las dependencias del `pubspec.yaml` según el diseño (flutter_riverpod, go_router, firebase_core, firebase_auth, cloud_firestore, firebase_storage, pdf, printing, path_provider, url_launcher, intl, mocktail, fast_check).
    - Agregar comentario educativo en `pubspec.yaml` explicando por qué se fijan versiones exactas.
    - _Requirements: 8.1, 9.1_

  - [ ] 1.2 Configurar Firebase con FlutterFire CLI
    - Instalar FlutterFire CLI y ejecutar `flutterfire configure` para generar `lib/firebase_options.dart`.
    - Verificar que `google-services.json` (Android) y `GoogleService-Info.plist` (si aplica) están en `.gitignore`.
    - Agregar comentario en `firebase_options.dart` indicando que es generado automáticamente y no debe editarse a mano.
    - _Requirements: 7.3, 9.2_

  - [ ] 1.3 Crear la estructura de carpetas `lib/`
    - Crear los directorios vacíos: `lib/models/`, `lib/providers/`, `lib/services/`, `lib/ui/screens/`, `lib/ui/widgets/`, `lib/ui/theme/`.
    - Crear el archivo `README.md` en la raíz con la descripción de la estructura de carpetas y el propósito de cada directorio.
    - _Requirements: 9.3_

- [ ] 2. Tema visual y constantes de la aplicación
  - [ ] 2.1 Implementar `app_colors.dart` y `app_theme.dart`
    - Crear `lib/ui/theme/app_colors.dart` con las constantes de color de la paleta institucional.
    - Crear `lib/ui/theme/app_theme.dart` con el `ThemeData` Material 3 neutro.
    - Agregar comentario explicando qué es Material 3 y por qué se usa como tema base.
    - _Requirements: 2.6, 9.1_

- [ ] 3. Modelo de datos `ReciboData`
  - [ ] 3.1 Implementar la clase inmutable `ReciboData`
    - Crear `lib/models/recibo_data.dart` con todos los campos del diseño (numeroRecibo, monto, montoEnTexto, recibiDe, concepto, dia, mes, anio, cajero, comandante).
    - Implementar `copyWith`, `toMap` y `factory fromMap`.
    - Implementar el constructor `ReciboData.empty()` necesario para el estado inicial del provider.
    - Agregar comentarios educativos explicando inmutabilidad y por qué Riverpod la prefiere.
    - _Requirements: 2.1, 3.3, 9.1, 9.4_

  - [ ]* 3.2 Escribir property test para serialización round-trip de `ReciboData`
    - Crear `test/models/recibo_data_test.dart`.
    - **Property: Round-trip de serialización** — para cualquier `ReciboData` válido, `ReciboData.fromMap(data.toMap())` debe ser igual a `data` campo a campo.
    - Usar `fast_check` para generar instancias aleatorias con números de recibo, montos y textos variados.
    - _Requirements: 3.3_

- [ ] 4. Servicio de generación de PDF (`PdfService`)
  - [ ] 4.1 Implementar `PdfService` con encabezado, cuerpo y sección de firmas
    - Crear `lib/services/pdf_service.dart`.
    - Implementar `generate(ReciboData data) → Future<Uint8List>` usando el paquete `pdf ^3.x`.
    - Configurar el formato de página carta (216 × 279 mm).
    - Implementar `_buildHeader()` con el texto fijo "FUERZA AÉREA BOLIVIANA / ESC. DE PERFEC. TÉCNICO AERONÁUTICO / BOLIVIA".
    - Implementar `_buildBody(data)` con la tabla de campos del formulario.
    - Implementar `_buildSignatureSection(data)` con los bloques de firma izquierdo (CAJERO EPTA) y derecho (COMANDANTE DE LA EPTA).
    - Agregar comentario explicando por qué se retorna `Uint8List` en lugar de un `File` para compatibilidad Web/Android.
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 4.2 Escribir property test para `PdfService` (Property 5)
    - Crear `test/services/pdf_service_test.dart`.
    - **Property 5: El PDF generado siempre tiene tamaño carta y contiene todos los datos**
    - Verificar que `generate(data)` retorna `Uint8List` no vacío para cualquier `ReciboData` válido generado aleatoriamente.
    - Verificar que los bytes producidos son un PDF válido (comienza con `%PDF`).
    - Usar `fast_check` con mínimo 100 iteraciones.
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.6**

- [ ] 5. Servicio Firebase (`FirebaseService`)
  - [ ] 5.1 Implementar la clase `FirebaseService` con inyección de dependencias
    - Crear `lib/services/firebase_service.dart`.
    - Implementar el constructor con parámetros opcionales `auth`, `db`, `storage` (inyección de dependencias para facilitar mocks en tests).
    - Implementar `authStateChanges`, `signInWithEmail`, `registerWithEmail` y `signOut`.
    - Implementar `uploadPdf(userId, numeroRecibo, bytes)` que sube a `recibos/{userId}/{timestamp}_{numeroRecibo}.pdf` y retorna la URL de descarga.
    - Implementar `saveReciboMetadata(data, userId, storageUrl)` que escribe el documento en Firestore con `serverTimestamp()`.
    - Implementar `watchRecibos(userId)` con filtro por `userId` y `orderBy('creadoEn', descending: true)`.
    - Agregar comentarios explicando la consulta compuesta de Firestore y la necesidad del índice.
    - _Requirements: 4.2, 4.4, 5.1, 5.2, 7.1, 7.2_

  - [ ]* 5.2 Escribir unit tests con mocks para `FirebaseService`
    - Crear `test/services/firebase_service_test.dart`.
    - Usar `mocktail` para crear mocks de `FirebaseAuth`, `FirebaseFirestore` y `FirebaseStorage`.
    - Verificar que `signInWithEmail` propaga `FirebaseAuthException` correctamente.
    - Verificar que `saveReciboMetadata` escribe todos los campos requeridos (Property 6).
    - Verificar que `watchRecibos` filtra por `userId` (Property 7).
    - **Validates: Requirements 4.4, 5.1, 7.1**

- [ ] 6. Providers Riverpod
  - [ ] 6.1 Implementar `firebaseServiceProvider` y `authStateProvider`
    - Crear `lib/providers/auth_provider.dart`.
    - Definir `firebaseServiceProvider` como `Provider<FirebaseService>`.
    - Definir `authStateProvider` como `StreamProvider<User?>` que escucha `authStateChanges`.
    - Agregar comentario educativo explicando por qué se usa `StreamProvider` para auth y qué es `AsyncValue`.
    - _Requirements: 1.1, 6.2, 7.4, 9.1_

  - [ ] 6.2 Implementar `ReciboFormNotifier` y `reciboFormProvider`
    - Crear `lib/providers/recibo_form_provider.dart`.
    - Implementar `ReciboFormNotifier extends StateNotifier<ReciboData>` con `updateField` y `reset`.
    - Definir `reciboFormProvider` como `StateNotifierProvider`.
    - Agregar comentario educativo explicando `StateNotifier` vs `setState` y la inmutabilidad del estado.
    - _Requirements: 2.1, 6.4, 9.1_

  - [ ] 6.3 Implementar `historialProvider`
    - Crear `lib/providers/historial_provider.dart`.
    - Definir `historialProvider` como `StreamProvider<List<Map<String, dynamic>>>` que retorna `Stream.empty()` si el usuario no está autenticado.
    - _Requirements: 5.1, 5.2_

  - [ ]* 6.4 Escribir tests para providers
    - Crear `test/providers/recibo_form_provider_test.dart` y `test/providers/auth_provider_test.dart`.
    - Verificar con `mocktail` que `ReciboFormNotifier.updateField` muta correctamente cada campo.
    - Verificar con `ProviderContainer` que `historialProvider` retorna `Stream.empty()` cuando no hay usuario.
    - _Requirements: 2.1, 5.1_

- [ ] 7. Router y entrada de la aplicación
  - [ ] 7.1 Implementar `router.dart` con `go_router` y guard de autenticación
    - Crear `lib/router.dart` con `routerProvider` (Provider<GoRouter>).
    - Definir las rutas: `/login`, `/register`, `/form`, `/preview`, `/history`.
    - Implementar el `redirect` que envía a `/login` si no hay usuario autenticado intentando acceder a rutas protegidas, y a `/form` si hay usuario autenticado intentando acceder a rutas de auth.
    - Agregar comentario educativo explicando route guards en go_router y Navigator 2.0.
    - _Requirements: 6.1, 6.2, 6.3, 7.4_

  - [ ]* 7.2 Escribir property test para el guard de navegación (Properties 10 y 11)
    - Crear `test/providers/historial_provider_test.dart` e incluir tests del router.
    - **Property 10: El guard redirige a `/login` para cualquier ruta protegida cuando el usuario no está autenticado**
    - **Property 11: Cualquier cambio de estado a no-autenticado desencadena redirección a `/login`**
    - Usar `ProviderContainer` con mock de `authStateProvider` que emite `null`.
    - **Validates: Requirements 6.2, 7.4**

  - [ ] 7.3 Implementar `app.dart` y `main.dart`
    - Crear `lib/app.dart` con `MaterialApp.router` que consume `routerProvider` y aplica `AppTheme.lightTheme`.
    - Actualizar `lib/main.dart`: inicializar Firebase con `Firebase.initializeApp`, envolver en `ProviderScope` y llamar a `runApp(const App())`.
    - Agregar comentario explicando por qué `ProviderScope` debe estar en la raíz del árbol de widgets.
    - _Requirements: 8.1, 9.2_

- [ ] 8. Checkpoint — Arquitectura base
  - Asegurarse de que el proyecto compila en Android y Web sin errores (`flutter build web`).
  - Ejecutar `flutter analyze` y corregir todos los warnings de linter.
  - Asegurarse de que todos los tests hasta aquí pasan. Preguntar al usuario si tiene dudas sobre la arquitectura antes de continuar.

- [ ] 9. Widgets reutilizables
  - [ ] 9.1 Implementar `FormFieldLabeled`
    - Crear `lib/ui/widgets/form_field_labeled.dart`.
    - Encapsular `TextFormField` con parámetros: `label`, `controller`, `validator`, `keyboardType`, `inputFormatters`.
    - Aplicar estilo Material 3 (usando `InputDecoration` con `OutlineInputBorder`).
    - Agregar comentario explicando el patrón widget reutilizable vs duplicar código.
    - _Requirements: 2.1, 2.6_

  - [ ] 9.2 Implementar `ReciboItemCard`
    - Crear `lib/ui/widgets/recibo_item_card.dart`.
    - Mostrar número de recibo, concepto, monto y fecha a partir de `Map<String, dynamic>`.
    - Usar `Card` + `ListTile` con acción `onTap`.
    - _Requirements: 5.3_

- [ ] 10. Pantalla de Login (`LoginScreen`)
  - [ ] 10.1 Implementar `LoginScreen` con formulario y manejo de errores
    - Crear `lib/ui/screens/login_screen.dart`.
    - Mostrar campos email y contraseña con `FormFieldLabeled`, botón de inicio de sesión y enlace a registro.
    - Llamar a `firebaseServiceProvider.signInWithEmail` desde el provider y manejar `FirebaseAuthException` mostrando "Correo o contraseña incorrectos".
    - Mostrar `CircularProgressIndicator` mientras se procesa el login.
    - _Requirements: 1.1, 1.6, 1.7_

  - [ ]* 10.2 Escribir unit test para `LoginScreen`
    - Crear `test/ui/login_screen_test.dart`.
    - Verificar que el botón de login está deshabilitado mientras hay carga.
    - Verificar que se muestra el mensaje de error para credenciales inválidas.
    - _Requirements: 1.7_

- [ ] 11. Pantalla de Registro (`RegisterScreen`)
  - [ ] 11.1 Implementar `RegisterScreen` con validación de contraseñas
    - Crear `lib/ui/screens/register_screen.dart`.
    - Mostrar campos email, contraseña y confirmación de contraseña.
    - Validar que ambas contraseñas coincidan en el cliente antes de invocar Firebase; mostrar "Las contraseñas no coinciden" si difieren.
    - Manejar `email-already-in-use` mostrando "El correo electrónico ya está en uso".
    - Agregar comentario explicando por qué la validación local evita llamadas innecesarias a Firebase.
    - _Requirements: 1.2, 1.3, 1.4, 1.5_

  - [ ]* 11.2 Escribir property test para validación de contraseñas (Properties 1 y 2)
    - Crear `test/ui/register_screen_test.dart`.
    - **Property 1: Registro válido siempre es aceptado** — para cualquier email válido y contraseña ≥ 6 caracteres, el formulario no debe mostrar error de formato.
    - **Property 2: Contraseñas distintas siempre son rechazadas** — para cualquier par de strings distintos, el botón de registro no invoca Firebase.
    - Usar `fast_check` para generar pares de contraseñas.
    - **Validates: Requirements 1.3, 1.5**

- [ ] 12. Pantalla del formulario (`FormScreen`)
  - [ ] 12.1 Implementar `FormScreen` con todos los campos y validación
    - Crear `lib/ui/screens/form_screen.dart`.
    - Mostrar el encabezado fijo no editable "FUERZA AÉREA BOLIVIANA…" como `Text` decorativo.
    - Usar `FormFieldLabeled` para los 10 campos: numeroRecibo, monto, montoEnTexto, recibiDe, concepto, dia, mes, anio, cajero, comandante.
    - Configurar `FilteringTextInputFormatter` en el campo `monto` para aceptar solo decimales de hasta 2 dígitos.
    - Usar `GlobalKey<FormState>` y `validate()` al presionar "Generar PDF".
    - Conectar cada campo a `reciboFormProvider` llamando `updateField` en `onChanged`.
    - _Requirements: 2.1, 2.2, 2.3, 2.5, 2.6_

  - [ ] 12.2 Implementar la lógica de generación PDF y navegación a `PreviewScreen`
    - Al presionar "Generar PDF" con el formulario válido: mostrar `CircularProgressIndicator`, deshabilitar el botón, llamar a `PdfService.generate(reciboData)` y navegar a `/preview` pasando los bytes por `GoRouter extra`.
    - Capturar excepciones del `PdfService` y mostrar `SnackBar` con el mensaje de error.
    - _Requirements: 2.4, 2.7, 3.6, 3.7_

  - [ ]* 12.3 Escribir property test para validación del formulario (Properties 3 y 4)
    - Agregar a `test/ui/form_screen_test.dart`.
    - **Property 3: Formulario rechaza cualquier campo vacío** — para cualquier subconjunto de campos en blanco, todos deben mostrar error de validación y no debe ocurrir navegación.
    - **Property 4: Validador de monto acepta solo formato numérico decimal válido** — para cualquier string, el validador acepta si y solo si es número decimal no negativo con ≤ 2 decimales.
    - **Validates: Requirements 2.3, 2.5**

- [ ] 13. Pantalla de previsualización (`PreviewScreen`)
  - [ ] 13.1 Implementar `PreviewScreen` con `PdfPreview` y acciones Guardar/Compartir
    - Crear `lib/ui/screens/preview_screen.dart`.
    - Recibir `Uint8List pdfBytes` desde `GoRouterState.extra`.
    - Mostrar el PDF con el widget `PdfPreview` del paquete `printing`.
    - Implementar botón "Guardar": deshabilitar botones durante la subida, llamar `FirebaseService.uploadPdf` + `saveReciboMetadata`, mostrar `SnackBar` de confirmación y navegar a `/history`.
    - Implementar botón "Compartir": llamar `Printing.sharePdf(bytes: pdfBytes)`.
    - Manejar error de Storage con `SnackBar` "Error al guardar el recibo. Intente nuevamente." conservando bytes en memoria.
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

  - [ ]* 13.2 Escribir unit test para `PreviewScreen`
    - Crear `test/ui/preview_screen_test.dart`.
    - Verificar que los botones se deshabilitan durante la operación de guardado.
    - Verificar que el `SnackBar` de error aparece cuando `FirebaseService` lanza excepción.
    - _Requirements: 4.5, 4.6_

- [ ] 14. Pantalla de historial (`HistoryScreen`)
  - [ ] 14.1 Implementar `HistoryScreen` con `StreamProvider` y estados de carga/error/vacío
    - Crear `lib/ui/screens/history_screen.dart`.
    - Consumir `historialProvider` con `ref.watch`.
    - Manejar los tres estados de `AsyncValue`: `loading` → `CircularProgressIndicator`, `error` → "Error al cargar el historial. Intente nuevamente.", `data` con lista vacía → "No tienes recibos generados aún.", `data` con ítems → `ListView.builder` con `ReciboItemCard`.
    - Al hacer tap en un ítem: llamar `launchUrl(Uri.parse(storageUrl))`.
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

  - [ ]* 14.2 Escribir property test para `HistoryScreen` (Properties 7, 8 y 9)
    - Crear `test/ui/history_screen_test.dart`.
    - **Property 7: El historial filtra exclusivamente por el usuario autenticado** — verificar que ningún recibo de otro `userId` aparece en la lista.
    - **Property 8: El historial está ordenado descendente por `creadoEn`** — para cualquier lista de recibos, verificar que `r_i.creadoEn >= r_{i+1}.creadoEn` para todo par adyacente.
    - **Property 9: Los ítems muestran todos los campos requeridos** — `ReciboItemCard` debe contener número de recibo, concepto, monto y fecha como texto visible.
    - Usar `fast_check` para generar listas de metadatos de recibos.
    - **Validates: Requirements 5.1, 5.2, 5.3**

- [ ] 15. Diseño responsivo
  - [ ] 15.1 Añadir `LayoutBuilder` responsivo a `FormScreen` e `HistoryScreen`
    - Envolver el contenido de `FormScreen` e `HistoryScreen` en `LayoutBuilder`.
    - Si `constraints.maxWidth >= 1024`: mostrar layout de dos columnas (formulario | preview en `FormScreen`; lista | detalle en `HistoryScreen`).
    - Si ancho < 1024: columna única con scroll.
    - Agregar comentario explicando por qué `LayoutBuilder` es preferible a detectar la plataforma.
    - _Requirements: 8.4_

  - [ ]* 15.2 Escribir property test de responsividad (Property 12)
    - Agregar tests en `test/ui/form_screen_test.dart`.
    - **Property 12: La UI es responsiva para cualquier ancho de pantalla en [360dp, ∞)**
    - Verificar que no hay overflow de píxeles y que el botón "Generar PDF" y los campos obligatorios son visibles.
    - Usar `fast_check` para generar anchos aleatorios en el rango [360, 2560].
    - **Validates: Requirements 8.4**

- [ ] 16. Barra de navegación inferior
  - [ ] 16.1 Implementar `NavigationBar` con accesos a `FormScreen` e `HistoryScreen`
    - Agregar `NavigationBar` (Material 3) con dos destinos: "Nuevo Recibo" (ícono de formulario) e "Historial" (ícono de lista) en las pantallas protegidas.
    - Usar `go_router` para la navegación entre destinos.
    - _Requirements: 6.1_

- [ ] 17. Reglas de seguridad Firebase
  - [ ] 17.1 Crear `firestore.rules` con reglas de acceso por `userId`
    - Crear el archivo `firestore.rules` en la raíz del proyecto con las reglas del diseño: `allow read, write` solo si `request.auth.uid == resource.data.userId` y `allow create` si `request.auth.uid == request.resource.data.userId`.
    - Agregar comentario explicando la diferencia entre `resource.data` (documento existente) y `request.resource.data` (documento en creación).
    - _Requirements: 7.1_

  - [ ] 17.2 Crear `storage.rules` con reglas de acceso por ruta `userId`
    - Crear el archivo `storage.rules` en la raíz del proyecto con las reglas del diseño: `allow read, write` dentro de `recibos/{userId}/{allPaths=**}` solo si `request.auth.uid == userId`.
    - Agregar comentario explicando por qué el `userId` en la ruta permite reglas eficientes sin consultas adicionales.
    - _Requirements: 7.2_

  - [ ] 17.3 Crear `firestore.indexes.json` para la consulta compuesta del historial
    - Crear `firestore.indexes.json` con el índice compuesto para la colección `recibos` sobre los campos `userId` (ASC) y `creadoEn` (DESC).
    - Agregar comentario explicando por qué Firestore requiere un índice para consultas que combinan `where` con `orderBy`.
    - _Requirements: 5.2_

- [ ] 18. Configuración de despliegue en Vercel
  - [ ] 18.1 Crear `vercel.json` para servir la build web de Flutter
    - Crear `vercel.json` en la raíz del proyecto con la configuración para servir `build/web` como sitio estático.
    - Configurar `rewrites` para que todas las rutas apunten a `index.html` (necesario para go_router en web).
    - Agregar comentario explicando por qué se necesita el rewrite para SPAs (Single Page Applications).
    - _Requirements: 8.2_

  - [ ] 18.2 Documentar el proceso de build y despliegue en `README.md`
    - Actualizar `README.md` con el comando `flutter build web --release` y los pasos para deployar en Vercel (conectar repo, directorio de salida `build/web`).
    - _Requirements: 8.2, 9.3_

- [ ] 19. Comentarios educativos y documentación final
  - [ ] 19.1 Revisar y completar comentarios educativos en todos los archivos Dart
    - Verificar que cada archivo `.dart` tiene comentario de cabecera con propósito, razón de la estructura y decisiones de diseño relevantes.
    - Verificar que los bloques de lógica no trivial (llamadas Firebase, construcción PDF, validaciones) tienen comentarios explicando el "por qué".
    - Agregar comentario educativo al `README.md` con el glosario del proyecto.
    - _Requirements: 9.1, 9.2, 9.4_

- [ ] 20. Checkpoint final — Integración y tests completos
  - Ejecutar `flutter test` y asegurarse de que todos los tests pasan.
  - Ejecutar `flutter analyze` sin warnings ni errores.
  - Ejecutar `flutter build web` y verificar que el artefacto se genera sin errores.
  - Verificar navegación completa: login → registro → formulario → preview → historial → cerrar sesión.
  - Preguntar al usuario si quiere ajustar algo antes de dar el proyecto por completado.

## Notes

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido.
- El orden es pedagógico: modelos → servicios → providers → pantallas → integración.
- Cada tarea referencia requisitos específicos para trazabilidad.
- Los property tests usan el paquete `fast_check` (Dart) con mínimo 100 iteraciones.
- Los tests unitarios usan `mocktail` para aislar dependencias de Firebase.
- Los checkpoints en tareas 8 y 20 validan la integración incremental.
- El comentario educativo en cada archivo es parte del requisito 9, no opcional.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["2.1", "3.1"] },
    { "id": 2, "tasks": ["3.2", "4.1", "9.1", "9.2"] },
    { "id": 3, "tasks": ["4.2", "5.1"] },
    { "id": 4, "tasks": ["5.2", "6.1"] },
    { "id": 5, "tasks": ["6.2", "6.3"] },
    { "id": 6, "tasks": ["6.4", "7.1"] },
    { "id": 7, "tasks": ["7.2", "7.3"] },
    { "id": 8, "tasks": ["10.1", "11.1"] },
    { "id": 9, "tasks": ["10.2", "11.2", "12.1"] },
    { "id": 10, "tasks": ["12.2"] },
    { "id": 11, "tasks": ["12.3", "13.1"] },
    { "id": 12, "tasks": ["13.2", "14.1"] },
    { "id": 13, "tasks": ["14.2", "15.1"] },
    { "id": 14, "tasks": ["15.2", "16.1"] },
    { "id": 15, "tasks": ["17.1", "17.2", "17.3"] },
    { "id": 16, "tasks": ["18.1", "18.2"] },
    { "id": 17, "tasks": ["19.1"] }
  ]
}
```
