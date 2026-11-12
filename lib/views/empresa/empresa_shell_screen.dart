import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/empresa_retos_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/adaptive_nav.dart';
import 'empresa_detalle_screen.dart';
import 'empresa_escanear_screen.dart';
import 'empresa_form_screen.dart';
import 'empresa_panel_screen.dart';
import 'empresa_perfil_screen.dart';
import 'empresa_retos_screen.dart';

/// Contador de la barra: candidatos + entregas por revisar.
///
/// Es un `Provider<int>` derivado, no el `StateNotifierProvider` completo.
/// Si el shell observara el StateNotifier, cada carga de "Mis retos"
/// reconstruiría el shell y la pestaña a la vez, y el árbol entraba en un bucle
/// de rebuild que dejaba la app congelada y llenaba la consola de
/// "Cannot hit test a render box with no size".
final _pendientesProvider = Provider<int>((ref) {
  try {
    final state = ref.watch(empresaRetosControllerProvider);
    return state.contadores.candidatosPorRevisar +
        state.contadores.entregasPorRevisar;
  } catch (_) {
    return 0;
  }
});

/// Qué pestaña abre el shell al construirse.
enum PantallaInicial { panel, retos, escanear, perfil, detalleReto, formReto }

/// Contenedor de las pantallas de empresa con navegación.
///
/// Barra: **Panel · Mis retos · Escanear QR · Perfil** y cerrar sesión.
class EmpresaShellScreen extends ConsumerStatefulWidget {
  const EmpresaShellScreen({
    super.key,
    this.inicio,
    this.retoId,
    this.pestanaInicial = 0,
  });

  /// Pestaña inicial. Si es null, se deduce de la URL.
  final PantallaInicial? inicio;

  /// Id del reto cuando la ruta es `/empresa/retos/:id` o `/:id/editar`.
  final String? retoId;

  /// Pestaña con la que se abre el detalle (0-3). Viene del query param
  /// `?pestana=` para que "Revisar" abra directo en Candidatos.
  final int pestanaInicial;

  @override
  ConsumerState<EmpresaShellScreen> createState() => _EmpresaShellScreenState();
}

class _EmpresaShellScreenState extends ConsumerState<EmpresaShellScreen> {
  static const _destinations = <AdaptiveNavDestination>[
    AdaptiveNavDestination(
      label: 'Panel',
      icon: Icons.space_dashboard_outlined,
      path: '/empresa',
    ),
    AdaptiveNavDestination(
      label: 'Mis retos',
      icon: Icons.emoji_events_outlined,
      path: '/empresa/retos',
    ),
    AdaptiveNavDestination(
      label: 'Escanear QR',
      icon: Icons.qr_code_scanner,
      path: '/empresa/escanear',
    ),
    AdaptiveNavDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      path: '/empresa/perfil',
    ),
  ];

  Future<void> _onSelect(int index) async {
    if (index == -1) {
      final salir = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Cerrar sesión?'),
          content: const Text(
            'Tendrás que volver a ingresar con tu correo y contraseña.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      if (salir != true) return;
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/landing');
      return;
    }
    if (index < 0 || index >= _destinations.length) return;
    // Navega a la ruta de la pestaña: la pantalla se deduce de la URL. Antes
    // solo se cambiaba un índice interno y, estando en el detalle o en el
    // formulario, las pestañas no hacían nada.
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter == null) return; // Tests que montan el shell sin router.
    goRouter.go(_destinations[index].path);
  }

  Widget _pantallaActiva() {
    // Las rutas hijas (detalle y formulario) se montan dentro del shell para
    // que tengan Scaffold y barra.
    switch (widget.inicio) {
      case PantallaInicial.detalleReto:
        return EmpresaDetalleScreen(
          retoId: widget.retoId ?? '',
          pestanaInicial: widget.pestanaInicial,
        );
      case PantallaInicial.formReto:
        return EmpresaFormScreen(retoId: widget.retoId);
      case null:
      case PantallaInicial.panel:
      case PantallaInicial.retos:
      case PantallaInicial.escanear:
      case PantallaInicial.perfil:
        break;
    }

    // La pestaña activa se deduce de la URL (no de un índice interno): así
    // al navegar directo a /empresa/retos ya marca "Mis retos", y al volver
    // desde el detalle o el formulario no se queda la pantalla anterior.
    return switch (_indiceRuta) {
      1 => const EmpresaRetosScreen(),
      2 => const EmpresaEscanearScreen(),
      3 => const EmpresaPerfilScreen(),
      _ => const EmpresaPanelScreen(),
    };
  }

  /// Ruta actual de la app.
  String get _rutaActual {
    final goRouter = GoRouter.maybeOf(context);
    return goRouter?.routerDelegate.currentConfiguration.uri.toString() ?? '';
  }

  /// Índice de pestaña según la ruta actual.
  int get _indiceRuta => _indiceRutaDe(_rutaActual);

  static int _indiceRutaDe(String ruta) {
    if (ruta.startsWith('/empresa/retos')) return 1;
    if (ruta.startsWith('/empresa/escanear')) return 2;
    if (ruta.startsWith('/empresa/perfil')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;
    final pendientes = ref.watch(_pendientesProvider);
    // Pestaña activa según la URL (ver [_indiceRuta]).
    final indice = _indiceRuta;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          if (isDesktop)
            SafeArea(
              bottom: false,
              child: AdaptiveNav(
                destinations: _destinations,
                currentIndex: indice,
                onDestinationSelected: _onSelect,
                isLoggedIn: true,
                // El punto naranja en "Mis retos" con el contador.
                badgeIndex: 1,
                badgeCount: pendientes,
              ),
            ),
          // Solo se monta la pestaña activa: las otras no hacen peticiones ni
          // reconstruyen widgets mientras no se usan.
          //
          // Sin `PageStorage`: antes creaba un `PageStorageBucket` nuevo en
          // cada rebuild y la pantalla activa perdía su estado (scroll,
          // controladores) cada vez que el shell se reconstruía al cargar el
          // contador de pendientes.
          Expanded(child: _pantallaActiva()),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : AdaptiveNav(
              destinations: _destinations,
              currentIndex: indice,
              onDestinationSelected: _onSelect,
              badgeIndex: 1,
              badgeCount: pendientes,
            ),
    );
  }
}
