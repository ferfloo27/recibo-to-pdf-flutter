// lib/ui/screens/main_shell.dart
//
// IMPORTANTE (lección del bug que encontramos): `navigationShell` (que
// contiene los Navigators de cada pestaña, con SU PROPIO estado y las
// conexiones activas a Firestore) tiene que quedar SIEMPRE en la misma
// "posición" del árbol de widgets, sin importar si estamos en modo ancho o
// angosto. Antes usábamos dos widgets totalmente distintos (_ShellAncho
// con Row, _ShellAngosto con Scaffold+bottomNav) — al cambiar de uno a
// otro, Flutter no podía reconocer que era "el mismo" navigationShell y lo
// destruía y recreaba, cortando la conexión con Firestore.
//
// La solución: UN SOLO Scaffold, con la MISMA estructura Row siempre — el
// riel lateral se agranda/achica con AnimatedContainer, en vez de
// aparecer/desaparecer del árbol.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/service_providers.dart';

const _anchoBreakpoint = 700.0;
const _anchoRiel = 220.0;

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esAncho = constraints.maxWidth >= _anchoBreakpoint;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ReciboToPDF'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Cerrar sesión',
                onPressed: () => ref.read(authServiceProvider).cerrarSesion(),
              ),
            ],
          ),
          // La estructura Row + Expanded(navigationShell) es SIEMPRE la
          // misma, en ambos modos — lo único que cambia es el ancho del
          // primer hijo (el riel), animado con AnimatedContainer en vez de
          // agregarse/quitarse del árbol.
          body: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: esAncho ? _anchoRiel : 0,
                // clipBehavior evita que el contenido del riel se "vea"
                // asomando por fuera mientras width anima hacia 0.
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                child: OverflowBox(
                  minWidth: _anchoRiel,
                  maxWidth: _anchoRiel,
                  alignment: Alignment.centerLeft,
                  child: _RielLateral(navigationShell: navigationShell),
                ),
              ),
              // Expanded(child: navigationShell) queda SIEMPRE en el mismo
              // lugar del árbol — esto es lo que preserva su estado y la
              // conexión con Firestore al redimensionar la ventana.
              Expanded(child: navigationShell),
            ],
          ),
          bottomNavigationBar: esAncho
              ? null
              : NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => navigationShell.goBranch(
                    index,
                    initialLocation: index == navigationShell.currentIndex,
                  ),
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.description_outlined), label: 'Formulario'),
                    NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
                  ],
                ),
        );
      },
    );
  }
}

class _RielLateral extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const _RielLateral({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'Administración',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: NavigationRail(
              extended: true,
              backgroundColor: Colors.transparent,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.add_box_outlined),
                  label: Text('Generar Recibo'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  label: Text('Archivo de Historial'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}