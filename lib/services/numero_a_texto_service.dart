// lib/services/numero_a_texto_service.dart
//
// Convierte un monto (ej. 1240.50) al formato que se usa en recibos y
// cheques en español: "Un Mil Doscientos Cuarenta 50/100 Bolivianos".
//
// La lógica de números en español se arma agrupando de a 3 dígitos
// (unidades, miles, millones) y resolviendo cada grupo de 3 con las mismas
// reglas (centenas + decenas + unidades) — es la misma idea que "separar
// por comas cada 3 dígitos" cuando escribimos un número grande, pero
// convertido a palabras en vez de dígitos.

class NumeroATextoService {
  static const _unidades = [
    '', 'Uno', 'Dos', 'Tres', 'Cuatro', 'Cinco', 'Seis', 'Siete', 'Ocho', 'Nueve',
  ];

  // 10 a 29 tienen nombres irregulares en español (no siguen el patrón de
  // "Treinta y Uno" en adelante) — por eso van en su propia tabla, en vez
  // de calcularse con una fórmula.
  static const _diezAVeintinueve = [
    'Diez', 'Once', 'Doce', 'Trece', 'Catorce', 'Quince', 'Dieciséis',
    'Diecisiete', 'Dieciocho', 'Diecinueve', 'Veinte', 'Veintiuno', 'Veintidós',
    'Veintitrés', 'Veinticuatro', 'Veinticinco', 'Veintiséis', 'Veintisiete',
    'Veintiocho', 'Veintinueve',
  ];

  static const _decenas = [
    '', '', '', 'Treinta', 'Cuarenta', 'Cincuenta', 'Sesenta', 'Setenta',
    'Ochenta', 'Noventa',
  ];

  static const _centenas = [
    '', 'Ciento', 'Doscientos', 'Trescientos', 'Cuatrocientos', 'Quinientos',
    'Seiscientos', 'Setecientos', 'Ochocientos', 'Novecientos',
  ];

  /// Punto de entrada: recibe el monto completo (con centavos) y arma el
  /// texto final con el formato "... XX/100 Bolivianos".
  static String convertir(double monto) {
    final parteEntera = monto.floor();
    // Redondeamos los centavos a 2 decimales para evitar artefactos de
    // punto flotante (ej. que 20.10 se calcule internamente como 20.099999).
    final centavos = ((monto - parteEntera) * 100).round();

    final textoEntero = parteEntera == 0 ? 'Cero' : _convertirGrupo3Digitos(parteEntera, esRaiz: true);
    final centavosFormateados = centavos.toString().padLeft(2, '0');

    return '$textoEntero $centavosFormateados/100 Bolivianos';
  }

  /// Convierte cualquier entero no negativo a palabras, separándolo en
  /// grupos de "millones", "miles" y "unidades" (los últimos 3 dígitos).
  static String _convertirGrupo3Digitos(int numero, {bool esRaiz = false}) {
    if (numero == 0) return '';

    if (numero >= 1000000) {
      final millones = numero ~/ 1000000;
      final resto = numero % 1000000;
      final textoMillones = millones == 1
          ? 'Un Millón'
          : '${_convertirGrupo3Digitos(millones)} Millones';
      final textoResto = resto > 0 ? ' ${_convertirGrupo3Digitos(resto)}' : '';
      return '$textoMillones$textoResto';
    }

    if (numero >= 1000) {
      final miles = numero ~/ 1000;
      final resto = numero % 1000;
      // "Mil" a secas para 1000-1999 (NO "Un Mil", así se dice en
      // español), pero sí usamos el número completo para 2000 en adelante
      // (ej. "Dos Mil").
      final textoMiles = miles == 1 ? 'Mil' : '${_convertirGrupo3Digitos(miles)} Mil';
      final textoResto = resto > 0 ? ' ${_convertirGrupo3Digitos(resto)}' : '';
      return '$textoMiles$textoResto';
    }

    // A partir de acá, `numero` ya está garantizado entre 1 y 999.
    final buffer = StringBuffer();

    if (numero >= 100) {
      // "Cien" exacto (100), pero "Ciento X" para 101-199 — otra
      // irregularidad del español que hay que tratar aparte.
      if (numero == 100) return 'Cien';
      buffer.write(_centenas[numero ~/ 100]);
      final resto = numero % 100;
      if (resto > 0) buffer.write(' ${_convertirDecenaYUnidad(resto)}');
      return buffer.toString();
    }

    return _convertirDecenaYUnidad(numero);
  }

  /// Resuelve el rango 1-99, que es donde viven todas las irregularidades
  /// del español (10-29 con nombre propio, "Treinta y Uno" en adelante
  /// con "y" en el medio).
  static String _convertirDecenaYUnidad(int numero) {
    if (numero < 10) return _unidades[numero];
    if (numero < 30) return _diezAVeintinueve[numero - 10];

    final decena = numero ~/ 10;
    final unidad = numero % 10;
    if (unidad == 0) return _decenas[decena];
    return '${_decenas[decena]} y ${_unidades[unidad]}';
  }
}
