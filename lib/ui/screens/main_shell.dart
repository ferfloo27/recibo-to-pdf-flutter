// lib/ui/screens/main_shell.dart
//
// Un "shell" en go_router es un widget que envuelve a varias pantallas y
// se mantiene fijo mientras navegas entre ellas — acá, la BottomNavigationBar
// no se reconstruye cada vez que cambias de pestaña, solo cambia el
// contenido de arriba. `navigationShell` lo provee go_router automáticamente
// y ya sabe en qué pestaña estás y cómo cambiar de una a otra.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ReciboToPDF')),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // goBranch navega a la pestaña elegida. `initialLocation: true`
        // significa: si el usuario toca la pestaña en la que YA está,
        // vuelve a la pantalla inicial de esa rama en vez de no hacer nada
        // (útil si, por ejemplo, hubiera navegado más adentro de esa pestaña).
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.description_outlined), label: 'Formulario'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}