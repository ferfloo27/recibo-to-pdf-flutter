# Documento de Diseño — ReciboToPDF

## Overview

ReciboToPDF es una aplicación Flutter multiplataforma (Android + Web) para generar recibos institucionales PDF de la Fuerza Aérea Boliviana / EPTA. La arquitectura sigue el patrón **Repository + Providers (Riverpod)**, separando responsabilidades entre UI, lógica de negocio y acceso a datos. El enrutamiento declarativo usa `go_router`, el backend Firebase cubre Auth, Firestore y Storage, y la generación PDF usa los paquetes `pdf ^3.x` y `printing ^5.x`.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                     UI Layer                        │
│  screens/: FormScreen, PreviewScreen, HistoryScreen │
│  widgets/: campos reutilizables, ReciboPreviewerWidget│
│  theme/:   colores, tipografía Material 3           │
└───────────────────┬─────────────────────────────────┘
                    │ lee/escucha providers
┌───────────────────▼─────────────────────────────────┐
│                 Providers Layer (Riverpod)           │
│  authProvider, reciboFormProvider, historialProvider │
└───────────────────┬─────────────────────────────────┘
                    │ llama servicios
┌───────────────────▼─────────────────────────────────┐
│                 Services Layer                      │
│  PdfService, FirebaseService                        │
└───────────────────┬─────────────────────────────────┘
                    │ SDK Firebase / dart:typed_data
┌───────────────────▼─────────────────────────────────┐
│             External / Infrastructure               │
│  Firebase Auth, Firestore, Storage, pdf pkg         │
└─────────────────────────────────────────────────────┘
```

---

## Estructura de carpetas `lib/`

```
lib/
├── main.dart                        # Punto de entrada; inicializa Firebase y ProviderScope
├── firebase_options.dart            # Generado por flutterfire configure (no editar a mano)
├── app.dart                         # MaterialApp.router + tema + go_router
├── router.dart                      # Definición de rutas con go_router y redirect guard
│
├── models/
│   └── recibo_data.dart             # Clase de datos inmutable ReciboData
│
├── providers/
│   ├── auth_provider.dart           # StateNotifier para estado de autenticación
│   ├── recibo_form_provider.dart    # StateNotifier para datos del formulario en curso
│   └── historial_provider.dart      # StreamProvider para lista de recibos del usuario
│
├── services/
│   ├── pdf_service.dart             # Construcción del documento PDF
│   └── firebase_service.dart        # CRUD Firestore + upload Storage + Auth
│
└── ui/
    ├── screens/
    │   ├── login_screen.dart
    │   ├── register_screen.dart
    │   ├── form_screen.dart
    │   ├── preview_screen.dart
    │   └── history_screen.dart
    ├── widgets/
    │   ├── form_field_labeled.dart   # Campo de texto reutilizable con label y validación
    │   └── recibo_item_card.dart     # Card para ítem de historial
    └── theme/
        ├── app_theme.dart            # ThemeData Material 3 neutro
        └── app_colors.dart           # Constantes de color
```

> **¿Por qué esta estructura?** Se organiza por _función técnica_ (models, providers, services, ui) en lugar de por _pantalla_, porque los providers y servicios son compartidos entre múltiples pantallas. Esta es la convención recomendada para proyectos Flutter de mediano tamaño.

---

## Data Models

### `ReciboData` (inmutable)

```dart
// lib/models/recibo_data.dart
//
// Por qué es inmutable: Riverpod promueve el uso de objetos inmutables en el estado.
// Cuando los datos cambian, se crea una nueva instancia en lugar de mutar la existente,
// lo que hace que los cambios de estado sean predecibles y rastreables.

class ReciboData {
  final String numeroRecibo;       // Número correlativo del recibo
  final double monto;              // Monto en números (Bolivianos)
  final String montoEnTexto;       // Monto escrito en letras
  final String recibiDe;           // Nombre de quien entrega el dinero
  final String concepto;           // Razón del pago
  final int dia;                   // Día de emisión
  final String mes;                // Mes en texto (ej. "Enero")
  final int anio;                  // Año de emisión
  final String cajero;             // Nombre del Cajero EPTA
  final String comandante;         // Nombre del Comandante / Cnl.

  const ReciboData({
    required this.numeroRecibo,
    required this.monto,
    required this.montoEnTexto,
    required this.recibiDe,
    required this.concepto,
    required this.dia,
    required this.mes,
    required this.anio,
    required this.cajero,
    required this.comandante,
  });

  // copyWith permite actualizar campos individuales manteniendo inmutabilidad
  ReciboData copyWith({ ... });

  // toMap serializa para Firestore
  Map<String, dynamic> toMap() => { ... };

  // fromMap deserializa desde Firestore
  factory ReciboData.fromMap(Map<String, dynamic> map) => ReciboData( ... );
}
```

### Documento Firestore — colección `recibos`

```jsonc
{
  "userId":      "string",         // UID de Firebase Auth
  "numeroRecibo": "string",
  "monto":        0.0,             // double
  "concepto":     "string",
  "fecha":        "string",        // "DD de MES de AAAA"
  "cajero":       "string",
  "comandante":   "string",
  "storageUrl":   "string",        // URL de descarga del PDF en Storage
  "creadoEn":     Timestamp        // serverTimestamp()
}
```

### Ruta Firebase Storage

```
recibos/{userId}/{timestamp}_{numeroRecibo}.pdf
```

> **¿Por qué incluir `userId` en la ruta?** Las reglas de seguridad de Storage se basan en la ruta del archivo. Al incluir `userId` en la ruta, podemos escribir una regla que compare `userId` con `request.auth.uid`, garantizando acceso exclusivo sin consultas adicionales.

---

## Components and Interfaces

### `PdfService`

Responsabilidad única: construir el PDF y devolver `Uint8List` (bytes).

```dart
// lib/services/pdf_service.dart
//
// Por qué retornamos Uint8List: el paquete 'pdf' construye el documento en memoria
// como bytes. Al retornar bytes en lugar de un File, el servicio es independiente
// del sistema de archivos y funciona igual en Android y Web.

class PdfService {
  static const _pageFormat = PdfPageFormat(
    216 * PdfPageFormat.mm,   // ancho carta
    279 * PdfPageFormat.mm,   // alto carta
  );

  /// Genera el PDF para [data] y retorna sus bytes.
  /// Lanza [PdfGenerationException] si falla la construcción.
  Future<Uint8List> generate(ReciboData data) async {
    final pdf = Document();

    pdf.addPage(
      Page(
        pageFormat: _pageFormat,
        build: (context) => Column(
          children: [
            _buildHeader(),           // Encabezado institucional fijo
            _buildBody(data),         // Campos del formulario
            _buildSignatureSection(data), // Firmas cajero y comandante
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Widget _buildHeader() => /* "FUERZA AÉREA BOLIVIANA / ESC. DE PERFEC..." */;
  Widget _buildBody(ReciboData data) => /* tabla de campos */;
  Widget _buildSignatureSection(ReciboData data) => /* dos bloques de firma */;
}
```

### `FirebaseService`

Abstrae todas las operaciones contra Firebase. Esto desacopla la UI de la implementación concreta, facilitando pruebas con mocks.

```dart
// lib/services/firebase_service.dart

class FirebaseService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  // Constructor con inyección de dependencias — facilita pruebas unitarias
  FirebaseService({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = db ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // Auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  Future<void> signInWithEmail(String email, String password) async { ... }
  Future<void> registerWithEmail(String email, String password) async { ... }
  Future<void> signOut() async { ... }

  // Storage + Firestore
  Future<String> uploadPdf(String userId, String numeroRecibo, Uint8List bytes) async { ... }
  Future<void> saveReciboMetadata(ReciboData data, String userId, String storageUrl) async { ... }

  // Historial
  Stream<List<Map<String, dynamic>>> watchRecibos(String userId) {
    // Por qué orderBy + where: Firestore requiere un índice compuesto para
    // consultas que combinan filtro de igualdad con ordenamiento. Se debe
    // crear el índice en Firebase Console o via firestore.indexes.json.
    return _db
        .collection('recibos')
        .where('userId', isEqualTo: userId)
        .orderBy('creadoEn', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}
```

### Providers (Riverpod)

```dart
// lib/providers/auth_provider.dart
//
// Por qué usamos StreamProvider para auth: Firebase expone el estado de
// autenticación como un Stream. StreamProvider de Riverpod convierte ese
// Stream en un AsyncValue que la UI puede consumir reactivamente, con
// manejo automático de estados loading/data/error.

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

// lib/providers/recibo_form_provider.dart
//
// Por qué StateNotifier: el formulario acumula cambios campo a campo.
// StateNotifier hace que cada cambio produzca un nuevo estado inmutable,
// facilitando el debugging y evitando mutaciones accidentales.

class ReciboFormNotifier extends StateNotifier<ReciboData> {
  ReciboFormNotifier() : super(const ReciboData.empty());

  void updateField(String field, dynamic value) { ... }
  void reset() { state = const ReciboData.empty(); }
}

final reciboFormProvider = StateNotifierProvider<ReciboFormNotifier, ReciboData>(
  (ref) => ReciboFormNotifier(),
);

// lib/providers/historial_provider.dart

final historialProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(firebaseServiceProvider).watchRecibos(user.uid);
});
```

---

## Navegación — `go_router`

### Rutas definidas

| Ruta          | Pantalla            | Requiere auth |
|---------------|---------------------|---------------|
| `/login`      | `LoginScreen`       | No            |
| `/register`   | `RegisterScreen`    | No            |
| `/form`       | `FormScreen`        | Sí            |
| `/preview`    | `PreviewScreen`     | Sí            |
| `/history`    | `HistoryScreen`     | Sí            |

### Guard de redirección

```dart
// lib/router.dart
//
// Por qué redirect en go_router: es el mecanismo declarativo para
// implementar "route guards". Se ejecuta antes de cada navegación,
// comparando el estado de auth con la ruta destino.

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register';

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/form';
      return null; // sin redirección
    },
    routes: [ ... ],
  );
});
```

---

## Interfaz de usuario

### `FormScreen`

- Widget `SingleChildScrollView` con `Column` de campos.
- Usa `GlobalKey<FormState>` para validación.
- Cada campo usa el widget reutilizable `FormFieldLabeled` que encapsula `TextFormField` con label, validador y estilo Material 3.
- El campo `monto` usa `inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]`.
- El botón "Generar PDF" es un `FilledButton` que, al presionarse:
  1. Llama a `_formKey.currentState!.validate()`.
  2. Si válido: llama a `PdfService.generate(data)` con estado de carga.
  3. Navega a `/preview` pasando los bytes por `extra`.

### `PreviewScreen`

- Recibe `Uint8List pdfBytes` vía `GoRouterState.extra`.
- Muestra `PdfPreview` del paquete `printing`.
- Botón "Guardar": llama a `FirebaseService.uploadPdf(...)` + `saveReciboMetadata(...)`.
- Botón "Compartir": llama a `Printing.sharePdf(bytes: pdfBytes)` (funciona en Android y Web).

### `HistoryScreen`

- Consume `historialProvider` (StreamProvider).
- Si `AsyncValue.loading`: muestra `CircularProgressIndicator`.
- Si `AsyncValue.error`: muestra mensaje de error.
- Si lista vacía: muestra texto "No tienes recibos generados aún."
- Si lista no vacía: `ListView.builder` con `ReciboItemCard`.
- Tap en ítem: `launchUrl(Uri.parse(storageUrl))` (usa `url_launcher`).

### Diseño responsivo

```dart
// Por qué LayoutBuilder: permite adaptar el layout en tiempo de ejecución
// al ancho disponible, sin necesidad de detectar la plataforma.

LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 1024) {
      return _buildDesktopLayout();  // dos columnas: form | preview
    }
    return _buildMobileLayout();     // columna única con scroll
  },
)
```

---

## Error Handling

| Origen                        | Error capturado                | Comportamiento                                              |
|-------------------------------|-------------------------------|-------------------------------------------------------------|
| Firebase Auth — registro      | `email-already-in-use`        | Muestra "El correo electrónico ya está en uso"             |
| Firebase Auth — login         | `wrong-password`, `user-not-found` | Muestra "Correo o contraseña incorrectos"            |
| PDF Generator                 | Cualquier excepción           | Muestra mensaje descriptivo, loguea en debugPrint          |
| Firebase Storage — upload     | `StorageException`            | Muestra "Error al guardar el recibo. Intente nuevamente."  |
| Firestore — lectura historial | `FirebaseException`           | Muestra "Error al cargar el historial. Intente nuevamente."|
| Auth — sesión expirada        | `authStateChanges` emite null | `go_router` redirect redirige a `/login`                   |

---

## Reglas de seguridad Firebase

### Firestore (`firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /recibos/{reciboId} {
      // Solo el dueño del documento puede leer/escribir.
      // request.auth.uid proviene del token JWT de Firebase Auth.
      allow read, write: if request.auth != null
                         && request.auth.uid == resource.data.userId;
      // Para creación (create), resource.data no existe todavía;
      // se usa request.resource.data.
      allow create: if request.auth != null
                    && request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### Firebase Storage (`storage.rules`)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /recibos/{userId}/{allPaths=**} {
      // El userId en la ruta debe coincidir con el UID del token.
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

---

## Flujo de datos completo

```
Usuario llena FormScreen
       │
       ▼
ReciboFormNotifier.updateField(...)   // Riverpod actualiza estado
       │
       ▼
Botón "Generar PDF"
       │
       ▼
PdfService.generate(reciboData)       // construye Uint8List en memoria
       │
       ▼
Navegar a PreviewScreen(pdfBytes)     // go_router extra: pdfBytes
       │
       ▼
Usuario presiona "Guardar"
       │
       ▼
FirebaseService.uploadPdf(...)        // Storage: recibos/{uid}/{ts}_{num}.pdf
       │
       ▼
FirebaseService.saveReciboMetadata(...)  // Firestore: colección recibos
       │
       ▼
Navegar a HistoryScreen               // go_router: /history
       │
       ▼
historialProvider escucha Firestore   // Stream en tiempo real actualiza lista
```

---

## Dependencias (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1      # Gestión de estado reactiva
  go_router: ^14.2.0            # Navegación declarativa Navigator 2.0
  firebase_core: ^3.3.0         # Inicialización de Firebase
  firebase_auth: ^5.1.0         # Autenticación por email
  cloud_firestore: ^5.2.0       # Base de datos NoSQL en tiempo real
  firebase_storage: ^12.1.0     # Almacenamiento de archivos
  pdf: ^3.11.1                  # Construcción de documentos PDF
  printing: ^5.13.1             # Renderizado, impresión y compartir PDFs
  path_provider: ^2.1.4         # Rutas del sistema de archivos (Android)
  share_plus: ^10.0.0           # Compartir archivos nativamente
  url_launcher: ^6.3.0          # Abrir URLs (historial web/Android)
  intl: ^0.19.0                 # Formateo de fechas y números

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^1.0.3              # Mocks para pruebas unitarias
  fast_check: ^0.1.0            # Property-based testing en Dart
```

> **¿Por qué versiones exactas?** Fijar versiones evita "dependency drift": que una actualización automática de una dependencia transitiva rompa la build sin cambios en el código propio.

---

## Testing Strategy

La estrategia de pruebas combina dos enfoques complementarios:

**Pruebas unitarias con ejemplos (Unit/Example tests)**
- Verifican comportamientos específicos con datos concretos: pantallas que muestran los widgets correctos, flujos de navegación para usuarios autenticados/no autenticados, mensajes de error con credenciales inválidas, estado de carga mientras se ejecutan operaciones asíncronas.
- Se usan mocks con `mocktail` para aislar `FirebaseService` y `PdfService` del código de UI y providers.
- Cubren casos de borde: lista de historial vacía, fallo de Storage, fallo de Firestore.

**Pruebas de propiedades (Property-Based Tests)**
- Usan el paquete `fast_check` (Dart) para generar entradas aleatorias y verificar invariantes universales.
- Mínimo 100 iteraciones por propiedad.
- Se enfocan en: validaciones de formulario, generación de PDF (dimensiones, contenido, bytes no vacíos), filtrado y ordenamiento del historial, guard de navegación.
- `PdfService` se prueba con `ReciboData` generado aleatoriamente; `FirebaseService` se prueba con mocks para evitar costos de red.

**Organización de tests**

```
test/
├── models/
│   └── recibo_data_test.dart          # serialización/deserialización round-trip
├── services/
│   ├── pdf_service_test.dart          # propiedades: bytes, tamaño, contenido
│   └── firebase_service_test.dart     # unit tests con mocks de Firebase
├── providers/
│   ├── auth_provider_test.dart
│   ├── recibo_form_provider_test.dart
│   └── historial_provider_test.dart
└── ui/
    ├── form_screen_test.dart          # validación, estado de carga
    ├── preview_screen_test.dart       # botones, acciones
    └── history_screen_test.dart       # lista, vacío, error
```

## Correctness Properties

*Una propiedad es una característica o comportamiento que debe ser verdadero en todas las ejecuciones válidas del sistema — esencialmente, un enunciado formal sobre lo que el sistema debe hacer. Las propiedades sirven como puente entre las especificaciones legibles por humanos y las garantías de corrección verificables automáticamente.*

### Property 1: Registro válido siempre es aceptado

*Para cualquier* dirección de email válida y contraseña de al menos 6 caracteres, el sistema debe aceptar el intento de registro y crear la cuenta sin rechazarlo por razones de formato.

**Validates: Requirements 1.3**

---

### Property 2: Contraseñas distintas siempre son rechazadas

*Para cualquier* par de strings que no sean idénticos entre sí, si se usan como `contraseña` y `confirmación de contraseña` en el formulario de registro, el sistema debe rechazar el envío y mostrar el mensaje de error correspondiente sin invocar Firebase Authentication.

**Validates: Requirements 1.5**

---

### Property 3: Validación del formulario rechaza cualquier campo vacío

*Para cualquier* subconjunto no vacío de los campos obligatorios de `FormScreen` que esté en blanco o compuesto únicamente de espacios en blanco, al presionar "Generar PDF" el sistema debe marcar cada uno de esos campos con un mensaje de error de validación e impedir la navegación a `PreviewScreen`.

**Validates: Requirements 2.3**

---

### Property 4: Validador de monto acepta solo formato numérico decimal válido

*Para cualquier* string de entrada, el validador del campo `monto` debe aceptarlo si y solo si es un número no negativo con a lo sumo dos dígitos decimales, y rechazarlo en cualquier otro caso.

**Validates: Requirements 2.5**

---

### Property 5: El PDF generado siempre tiene tamaño carta y contiene todos los datos

*Para cualquier* `ReciboData` válido, `PdfService.generate(data)` debe:
- Retornar `Uint8List` no vacío (bytes > 0).
- Producir un documento con dimensiones de página carta (216 × 279 mm).
- Incluir en el contenido del documento el texto del encabezado institucional, el número de recibo, el monto, el concepto, la fecha, el nombre del cajero y el nombre del comandante.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.6**

---

### Property 6: Los metadatos guardados en Firestore contienen todos los campos requeridos

*Para cualquier* `ReciboData` guardado correctamente, el documento escrito en la colección `recibos` de Firestore debe contener los campos `userId`, `numeroRecibo`, `monto`, `concepto`, `fecha`, `cajero`, `comandante`, `storageUrl` y `creadoEn`, con valores coherentes con los datos del recibo original.

**Validates: Requirements 4.4**

---

### Property 7: El historial filtra exclusivamente por el usuario autenticado

*Para cualquier* usuario autenticado y cualquier estado de la colección `recibos`, todos los documentos retornados por `FirebaseService.watchRecibos(userId)` deben tener el campo `userId` exactamente igual al identificador del usuario autenticado; ningún recibo de otro usuario debe aparecer en la lista.

**Validates: Requirements 5.1**

---

### Property 8: El historial está ordenado descendente por fecha de creación

*Para cualquier* lista no vacía de recibos retornada por `historialProvider`, para todo par adyacente de recibos `(r_i, r_{i+1})` en la lista, se debe cumplir `r_i.creadoEn >= r_{i+1}.creadoEn`.

**Validates: Requirements 5.2**

---

### Property 9: Los ítems del historial muestran todos los campos requeridos

*Para cualquier* mapa de metadatos de recibo retornado por Firestore, el widget `ReciboItemCard` renderizado a partir de ese mapa debe contener en su árbol de widgets el número de recibo, el concepto, el monto y la fecha como texto visible.

**Validates: Requirements 5.3**

---

### Property 10: El guard de navegación redirige a login para cualquier ruta protegida

*Para cualquier* ruta del conjunto `{/form, /preview, /history}`, si el estado de autenticación es no autenticado (`authStateProvider` retorna `null`), el guard de `go_router` debe redirigir la navegación a `/login` sin renderizar la pantalla destino.

**Validates: Requirements 6.2**

---

### Property 11: Cualquier cambio de estado a no-autenticado desencadena redirección a login

*Para cualquier* estado previo de la aplicación en el que el usuario estaba autenticado, si `authStateChanges` emite `null` (sesión expirada, revocada o cerrada manualmente), el sistema debe redirigir al usuario a la pantalla de inicio de sesión independientemente de la pantalla en la que se encontraba.

**Validates: Requirements 7.4**

---

### Property 12: La UI es responsiva para cualquier ancho de pantalla válido

*Para cualquier* ancho de pantalla en el rango `[360dp, ∞)`, el árbol de widgets de `FormScreen` e `HistoryScreen` no debe producir overflow de píxeles, ni ocultar controles críticos como el botón "Generar PDF" o los campos obligatorios del formulario.

**Validates: Requirements 8.4**
