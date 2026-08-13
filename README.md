# ReciboToPDF

App Flutter (Android + Web) para generar recibos institucionales de la EPTA
(Fuerza Aérea Boliviana) en formato PDF, con historial guardado en Firebase.

## Estructura de `lib/`

Organizamos el código por **función técnica** (no por pantalla), porque los
providers y servicios se comparten entre varias pantallas:

- `models/` — Clases de datos puras (ej. `ReciboData`). Sin lógica de Flutter,
  sin llamadas a red. Solo representan información.
- `providers/` — El "cerebro" del estado de la app (Riverpod). Cada provider
  observa datos (auth, formulario, historial) y notifica a la UI cuando cambian.
- `services/` — La capa que habla con el mundo exterior: Firebase y la
  generación del PDF. La UI nunca llama a Firebase directamente, siempre pasa
  por un service — así podemos reemplazar Firebase por otra cosa el día de
  mañana sin tocar las pantallas.
- `ui/screens/` — Las pantallas completas (Login, Form, Preview, History).
- `ui/widgets/` — Piezas reutilizables entre pantallas (un campo de texto con
  validación, una tarjeta de recibo).
- `ui/theme/` — Colores y tipografía centralizados (Material 3).

## Requisitos para correr el proyecto

- Flutter SDK (canal stable) instalado
- Una cuenta y proyecto de Firebase (gratis) — ver sección abajo
- Node no es necesario, pero sí `npm` si instalas Firebase CLI por ese medio

## Configurar Firebase (lo haces tú, una sola vez)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto te va a preguntar a qué proyecto de Firebase conectar la app (o crear uno
nuevo) y generará automáticamente `lib/firebase_options.dart` — **ese archivo
no se edita a mano**, se regenera si cambias de proyecto.

## Correr en desarrollo

```bash
flutter pub get
flutter run -d chrome      # para probar en Web
flutter run                # para un emulador/dispositivo Android conectado
```

## Desplegar la versión Web en Vercel

```bash
flutter build web --release
```

Luego conecta el repo a Vercel y configura el directorio de salida como
`build/web` (más detalles en `vercel.json`, que agregamos más adelante).