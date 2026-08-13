# Documento de Requisitos

## Introducción

ReciboToPDF es una aplicación Flutter multiplataforma (Android y Web) diseñada para generar recibos institucionales en formato PDF para la Fuerza Aérea Boliviana / Escuela de Perfeccionamiento Técnico Aeronáutico (EPTA). La aplicación permite a usuarios autenticados completar un formulario con los datos del recibo, previsualizar el documento generado, descargarlo o compartirlo, y consultar el historial personal de recibos almacenados. El backend se sustenta en Firebase (Authentication, Firestore, Storage) y el despliegue web se realiza en Vercel.

El código fuente incluirá comentarios educativos que explican el "por qué" de cada decisión de implementación, no solo el "qué", con el objetivo de servir como material de aprendizaje para los desarrolladores del equipo.

---

## Glosario

- **ReciboToPDF**: Nombre de la aplicación Flutter multiplataforma objeto de este documento.
- **App**: La aplicación ReciboToPDF en cualquiera de sus plataformas soportadas (Android, Web).
- **Usuario**: Persona registrada en la App con email y contraseña mediante Firebase Authentication.
- **Recibo**: Documento PDF que representa un recibo institucional de la EPTA con todos sus campos definidos.
- **FormScreen**: Pantalla de la App que contiene el formulario de ingreso de datos del recibo.
- **PreviewScreen**: Pantalla de la App que muestra la previsualización del PDF generado antes de guardarlo o compartirlo.
- **HistoryScreen**: Pantalla de la App que muestra el historial de recibos generados por el usuario autenticado.
- **Firebase Authentication**: Servicio de autenticación de Firebase usado para gestionar el registro e inicio de sesión de usuarios.
- **Firestore**: Base de datos NoSQL en tiempo real de Firebase usada para almacenar los metadatos de los recibos.
- **Firebase Storage**: Servicio de almacenamiento de archivos de Firebase usado para guardar los archivos PDF generados.
- **PDF Generator**: Componente de la App responsable de construir el documento PDF usando los paquetes `pdf` y `printing`.
- **Colección `recibos`**: Colección en Firestore donde se almacenan los documentos de metadatos de recibos, filtrados por `userId`.
- **Encabezado fijo**: Texto institucional que aparece en la parte superior del PDF: "FUERZA AÉREA BOLIVIANA / ESC. DE PERFEC. TÉCNICO AERONÁUTICO / BOLIVIA".
- **Cajero EPTA**: Funcionario que entrega el dinero; su nombre aparece en la firma izquierda del recibo.
- **Comandante**: Funcionario que recibe conformidad; su nombre aparece en la firma derecha del recibo.
- **Monto en texto**: Representación escrita del monto numérico (ej. "Cuarenta 00/100 Bolivianos").
- **Material 3**: Sistema de diseño visual moderno de Google implementado en Flutter, usado como tema neutro de la App.

---

## Requisitos

### Requisito 1 — Registro e inicio de sesión de usuarios

**Historia de usuario:** Como visitante de la App, quiero registrarme con mi email y contraseña y luego iniciar sesión, para poder usar todas las funciones de la aplicación de forma segura.

#### Criterios de aceptación

1. THE App SHALL presentar una pantalla de inicio de sesión con campos de email y contraseña como primer destino cuando no existe una sesión activa.
2. WHEN un visitante selecciona la opción de registro, THE App SHALL presentar un formulario de registro con campos de email, contraseña y confirmación de contraseña.
3. WHEN un visitante envía el formulario de registro con email válido y contraseñas coincidentes de al menos 6 caracteres, THE Firebase Authentication SHALL crear una cuenta nueva y la App SHALL iniciar sesión automáticamente con esa cuenta.
4. IF el email ingresado en el registro ya está registrado, THEN THE App SHALL mostrar el mensaje "El correo electrónico ya está en uso".
5. IF las contraseñas ingresadas en el registro no coinciden, THEN THE App SHALL mostrar el mensaje "Las contraseñas no coinciden" sin enviar la solicitud a Firebase Authentication.
6. WHEN un usuario registrado envía el formulario de inicio de sesión con credenciales válidas, THE Firebase Authentication SHALL autenticar al usuario y la App SHALL navegar a FormScreen.
7. IF las credenciales ingresadas en el inicio de sesión son inválidas, THEN THE App SHALL mostrar el mensaje "Correo o contraseña incorrectos".
8. WHEN un usuario autenticado selecciona la opción de cerrar sesión, THE App SHALL cerrar la sesión en Firebase Authentication y navegar a la pantalla de inicio de sesión.

---

### Requisito 2 — Formulario de datos del recibo (FormScreen)

**Historia de usuario:** Como usuario autenticado, quiero completar un formulario con todos los campos del recibo institucional, para generar un PDF correctamente estructurado.

#### Criterios de aceptación

1. THE FormScreen SHALL presentar los siguientes campos de entrada: número de recibo, monto en números (Bolivianos), monto en texto, recibí de, concepto, día, mes (texto), año, nombre del Cajero EPTA y nombre del Comandante / Cnl.
2. THE FormScreen SHALL mostrar el encabezado fijo "FUERZA AÉREA BOLIVIANA / ESC. DE PERFEC. TÉCNICO AERONÁUTICO / BOLIVIA" como referencia visual no editable dentro del formulario.
3. WHEN el usuario presiona el botón "Generar PDF" sin haber completado todos los campos obligatorios, THE FormScreen SHALL resaltar cada campo vacío con un mensaje de error de validación y SHALL impedir la navegación a PreviewScreen.
4. WHEN todos los campos obligatorios están completos y el usuario presiona "Generar PDF", THE FormScreen SHALL invocar al PDF Generator con los datos ingresados y navegar a PreviewScreen.
5. THE FormScreen SHALL aceptar el campo de monto en números únicamente con formato numérico decimal de hasta dos decimales.
6. THE FormScreen SHALL aplicar el tema Material 3 neutro en todos sus controles visuales (colores, tipografía, elevaciones).
7. WHILE la generación del PDF está en progreso, THE FormScreen SHALL mostrar un indicador de carga y SHALL deshabilitar el botón "Generar PDF" para evitar envíos duplicados.

---

### Requisito 3 — Generación del documento PDF

**Historia de usuario:** Como usuario autenticado, quiero que el PDF generado tenga el formato institucional correcto de la EPTA, para que el documento sea válido y profesional.

#### Criterios de aceptación

1. THE PDF Generator SHALL producir el documento en tamaño carta (216 × 279 mm).
2. THE PDF Generator SHALL incluir el encabezado fijo "FUERZA AÉREA BOLIVIANA / ESC. DE PERFEC. TÉCNICO AERONÁUTICO / BOLIVIA" en la parte superior del documento, en texto sin logotipos ni imágenes institucionales.
3. THE PDF Generator SHALL incluir todos los campos del formulario en el cuerpo del documento: número de recibo, monto en números, monto en texto, recibí de, concepto y fecha (día, mes en texto y año).
4. THE PDF Generator SHALL incluir en la sección de firmas dos bloques: el bloque izquierdo con "ENTREGUE CONFORME", el nombre del Cajero EPTA y la denominación "CAJERO EPTA"; y el bloque derecho con "RECIBÍ CONFORME", el nombre del Comandante / Cnl. y la denominación "COMANDANTE DE LA EPTA".
5. THE PDF Generator SHALL usar el paquete `pdf` versión 3.x y el paquete `printing` versión 5.x para construir y renderizar el documento.
6. WHEN el PDF Generator finaliza la construcción del documento, THE PDF Generator SHALL retornar los bytes del PDF a FormScreen para su uso en PreviewScreen.
7. IF el PDF Generator encuentra un error durante la construcción del documento, THEN THE App SHALL mostrar un mensaje de error descriptivo y SHALL registrar el error en la consola de depuración.

---

### Requisito 4 — Previsualización del PDF (PreviewScreen)

**Historia de usuario:** Como usuario autenticado, quiero previsualizar el PDF antes de guardarlo o compartirlo, para verificar que los datos son correctos.

#### Criterios de aceptación

1. THE PreviewScreen SHALL mostrar el documento PDF generado en un visor integrado usando el widget `PdfPreview` del paquete `printing`.
2. THE PreviewScreen SHALL ofrecer una acción "Guardar" que almacene el PDF en Firebase Storage y guarde los metadatos del recibo en la colección `recibos` de Firestore.
3. THE PreviewScreen SHALL ofrecer una acción "Compartir / Descargar" que permita al usuario descargar o compartir el archivo PDF directamente desde el visor.
4. WHEN el usuario selecciona "Guardar", THE App SHALL subir el archivo PDF a Firebase Storage en la ruta `recibos/{userId}/{timestamp}_{numeroRecibo}.pdf` y SHALL escribir en Firestore un documento con los campos: `userId`, `numeroRecibo`, `monto`, `concepto`, `fecha`, `cajero`, `comandante`, `storageUrl` y `creadoEn` (timestamp del servidor).
5. IF la subida a Firebase Storage falla, THEN THE App SHALL mostrar el mensaje "Error al guardar el recibo. Intente nuevamente." y SHALL conservar el PDF en memoria para reintentar.
6. WHILE la subida a Firebase Storage está en progreso, THE PreviewScreen SHALL mostrar un indicador de carga y SHALL deshabilitar las acciones "Guardar" y "Compartir / Descargar".
7. WHEN la operación de guardado finaliza exitosamente, THE App SHALL mostrar una notificación de confirmación y SHALL navegar a HistoryScreen.

---

### Requisito 5 — Historial de recibos (HistoryScreen)

**Historia de usuario:** Como usuario autenticado, quiero ver el listado de mis recibos generados anteriormente, para poder consultarlos o descargarlos cuando lo necesite.

#### Criterios de aceptación

1. THE HistoryScreen SHALL mostrar únicamente los recibos cuyo campo `userId` coincida con el identificador del usuario autenticado actual.
2. THE HistoryScreen SHALL listar los recibos en orden descendente por el campo `creadoEn`, mostrando el más reciente primero.
3. THE HistoryScreen SHALL mostrar por cada recibo en la lista: número de recibo, concepto, monto y fecha.
4. WHEN el usuario selecciona un recibo de la lista, THE App SHALL abrir el PDF correspondiente desde su URL de Firebase Storage en el visor del sistema o en una nueva pestaña del navegador (Web).
5. IF el usuario no tiene recibos guardados, THEN THE HistoryScreen SHALL mostrar el mensaje "No tienes recibos generados aún." en lugar de una lista vacía.
6. WHILE la App carga los recibos desde Firestore, THE HistoryScreen SHALL mostrar un indicador de carga en lugar del listado.
7. IF la carga de recibos desde Firestore falla, THEN THE HistoryScreen SHALL mostrar el mensaje "Error al cargar el historial. Intente nuevamente."

---

### Requisito 6 — Navegación y estructura de la aplicación

**Historia de usuario:** Como usuario autenticado, quiero navegar fácilmente entre las pantallas de la aplicación, para acceder a las funciones sin confusión.

#### Criterios de aceptación

1. THE App SHALL implementar una barra de navegación inferior con accesos directos a FormScreen e HistoryScreen mientras el usuario esté autenticado.
2. WHEN un usuario no autenticado intenta acceder a FormScreen, PreviewScreen o HistoryScreen directamente, THE App SHALL redirigirlo a la pantalla de inicio de sesión.
3. THE App SHALL usar el sistema de navegación declarativa de Flutter (Navigator 2.0 o `go_router`) para gestionar las rutas de las tres pantallas principales.
4. WHEN el usuario presiona el botón de retroceso desde PreviewScreen, THE App SHALL navegar de regreso a FormScreen conservando los datos del formulario previamente ingresados.

---

### Requisito 7 — Persistencia en Firebase y seguridad de datos

**Historia de usuario:** Como usuario autenticado, quiero que mis datos estén almacenados de forma segura en Firebase y solo sean accesibles por mí, para proteger la información institucional.

#### Criterios de aceptación

1. THE App SHALL configurar las reglas de seguridad de Firestore de forma que un usuario autenticado solo pueda leer y escribir documentos en la colección `recibos` donde el campo `userId` sea igual a su propio identificador de Firebase Authentication.
2. THE App SHALL configurar las reglas de seguridad de Firebase Storage de forma que un usuario autenticado solo pueda leer y escribir archivos dentro de la ruta `recibos/{userId}/`.
3. THE App SHALL inicializar Firebase usando las credenciales del proyecto correspondiente sin exponer claves privadas en el repositorio de código fuente.
4. IF la sesión del usuario expira o es revocada, THEN THE App SHALL detectar el estado de autenticación inválido y SHALL redirigir al usuario a la pantalla de inicio de sesión.

---

### Requisito 8 — Compatibilidad multiplataforma y despliegue Web

**Historia de usuario:** Como administrador del proyecto, quiero que la App funcione correctamente en Android y en navegadores web modernos desplegada en Vercel, para maximizar el alcance de los usuarios.

#### Criterios de aceptación

1. THE App SHALL compilar y ejecutarse correctamente en Android (API 21 o superior) y en Web (Chrome, Firefox y Edge en sus versiones estables más recientes).
2. THE App SHALL generar el artefacto web mediante `flutter build web` para su despliegue en Vercel como sitio estático.
3. WHEN la App es accedida en Web, THE PDF Generator SHALL usar la API `printing` compatible con el entorno web para la previsualización y descarga del PDF en el navegador.
4. THE App SHALL aplicar un diseño responsivo que sea usable tanto en pantallas de móvil (mínimo 360 dp de ancho) como en pantallas de escritorio (mínimo 1024 px de ancho).

---

### Requisito 9 — Calidad del código y modo aprendizaje

**Historia de usuario:** Como desarrollador del equipo EPTA, quiero que el código fuente tenga comentarios educativos que expliquen las decisiones de implementación, para aprender Flutter y Firebase durante el desarrollo.

#### Criterios de aceptación

1. THE App SHALL incluir comentarios en el código fuente en cada archivo Dart que expliquen el propósito del archivo, la razón de la estructura elegida y las decisiones de diseño relevantes.
2. THE App SHALL incluir comentarios en línea en cada bloque de lógica no trivial (llamadas a Firebase, construcción del PDF, validaciones) que expliquen el "por qué" de la implementación, no solo el "qué".
3. THE App SHALL organizar el código fuente siguiendo una estructura de carpetas por funcionalidad (`features/auth`, `features/recibo`, `features/historial`, `shared/`) documentada en un archivo `README.md` en la raíz del proyecto.
4. THE App SHALL usar nombres de variables, funciones y clases en inglés con documentación en español en los comentarios, para mantener consistencia con las convenciones de Flutter y facilitar la comprensión del equipo.
