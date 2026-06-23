import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

import '../../../../core/theme/app_theme.dart';

/// Navegador embebido (WebView2 / motor Edge-Chromium) que abre el portal de
/// GPS Alarma Inteligente dentro de la app. La sesión y las credenciales se
/// conservan en el perfil de WebView2, igual que en un navegador Chrome.
///
/// Carga la raíz del portal (no `/login`): si ya hay sesión activa, la
/// plataforma muestra el dashboard directamente; si no, ella misma presenta el
/// formulario de inicio de sesión.
///
/// Solo funciona en Windows escritorio. En otras plataformas muestra un aviso.
class GpsPortalScreen extends StatefulWidget {
  const GpsPortalScreen({super.key});

  static const portalUrl = 'https://gpsalarmainteligente.com/';

  @override
  State<GpsPortalScreen> createState() => _GpsPortalScreenState();
}

class _GpsPortalScreenState extends State<GpsPortalScreen> {
  final _controller = WebviewController();
  final _subscriptions = <StreamSubscription>[];

  bool _isLoading = true;
  String? _error;

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    if (_isWindows) {
      _initWebview();
    }
  }

  Future<void> _initWebview() async {
    try {
      await _controller.initialize();

      _subscriptions.add(
        _controller.loadingState.listen((state) {
          if (!mounted) return;
          setState(() => _isLoading = state == LoadingState.loading);
        }),
      );

      await _controller.setBackgroundColor(Colors.white);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl(GpsPortalScreen.portalUrl);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'No se pudo iniciar el navegador embebido.\n\n'
            'Verifica que el runtime "Microsoft Edge WebView2" esté instalado '
            '(viene incluido en Windows 11).\n\nDetalle: $e';
      });
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_fixed, color: AppTheme.azulPrimario, size: 20),
            SizedBox(width: AppTheme.spacingSm),
            Text('Portal GPS'),
          ],
        ),
        actions: _isWindows && _error == null
            ? [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  tooltip: 'Atrás',
                  onPressed: () => _controller.goBack(),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  tooltip: 'Adelante',
                  onPressed: () => _controller.goForward(),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recargar',
                  onPressed: () => _controller.reload(),
                ),
                const SizedBox(width: AppTheme.spacingSm),
              ]
            : null,
        bottom: _isLoading && _isWindows && _error == null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isWindows) {
      return const _GpsMessage(
        icon: Icons.desktop_windows_outlined,
        message:
            'El portal GPS embebido solo está disponible en la versión de '
            'Windows escritorio.',
      );
    }

    if (_error != null) {
      return _GpsMessage(
        icon: Icons.error_outline,
        message: _error!,
        isError: true,
      );
    }

    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Webview(_controller);
  }
}

class _GpsMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool isError;

  const _GpsMessage({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppTheme.error : context.c.textoSecundario;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, height: 1.5, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
