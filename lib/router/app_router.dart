import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/tariff/presentation/screens/tariff_screen.dart';
import '../features/tariff/presentation/screens/info_tarifas_screen.dart';
import '../features/historial/presentation/screens/historial_screen.dart';

/// Rutas nombradas — evita strings sueltos por toda la app (DRY).
abstract final class AppRoutes {
  static const home = '/';
  static const calcular = '/calcular';
  static const resultado = '/resultado';
  static const historial = '/historial';
  static const historialDetalle = '/historial/:id';
  static const vehiculos = '/vehiculos';
  static const vehiculoForm = '/vehiculos/form';
  static const peajes = '/peajes';
}

abstract final class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const TariffScreen(),
      ),
      GoRoute(
        path: AppRoutes.calcular,
        name: 'calcular',
        builder: (context, state) => const TariffScreen(),
      ),
      GoRoute(
        path: AppRoutes.resultado,
        name: 'resultado',
        builder: (context, state) => const _PlaceholderScreen(title: 'Resultado'),
      ),
      GoRoute(
        path: AppRoutes.historial,
        name: 'historial',
        builder: (context, state) => const HistorialScreen(),
      ),
      GoRoute(
        path: AppRoutes.vehiculos,
        name: 'vehiculos',
        builder: (context, state) => const _PlaceholderScreen(title: 'Vehículos'),
      ),
      GoRoute(
        path: AppRoutes.peajes,
        name: 'peajes',
        builder: (context, state) => const InfoTarifasScreen(),
      ),
    ],
  );
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
