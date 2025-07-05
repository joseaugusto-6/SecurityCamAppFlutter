import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart'; // ¡Importa esto!

// Definición de la URL del stream de video de tu PC
// ¡MUY IMPORTANTE! Reemplaza 'TU_IP_LOCAL_DEL_PC' con la IP real de tu PC
// (ej. '192.168.1.100'). Asegúrate de que tu PC esté corriendo camera_stream.py.
const String STREAM_URL = 'http://192.168.68.112:5000/';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key});

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Inicializar el controlador del WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Permitir JavaScript
      ..setBackgroundColor(const Color(0x00000000)) // Fondo transparente
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Puedes mostrar un indicador de progreso si lo deseas
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            setState(() {
              _isLoading = true; // Activar el cargador
              _errorMessage = '';
            });
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            setState(() {
              _isLoading = false; // Desactivar el cargador
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              Page resource error:
                code: ${error.errorCode}
                description: ${error.description}
                errorType: ${error.errorType}
                isForMainFrame: ${error.isForMainFrame}
                      ''');
            setState(() {
              _isLoading = false;
              _errorMessage = 'Error al cargar el stream: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Permite o bloquea la navegación dentro del WebView
            // Si quieres que el usuario no pueda navegar fuera de tu stream, puedes bloquearlo
            if (request.url.startsWith(STREAM_URL)) {
              return NavigationDecision.navigate;
            }
            debugPrint('Blocking navigation to ${request.url}');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(STREAM_URL)); // Cargar la URL de tu stream
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video en Vivo'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.reload(); // Recargar el WebView
            },
            tooltip: 'Recargar Stream',
          ),
        ],
      ),
      body: Stack(
        // Usar Stack para superponer el cargador
        children: [
          WebViewWidget(controller: _controller), // El widget WebView
          if (_isLoading) // Mostrar cargador si _isLoading es true
            const Center(child: CircularProgressIndicator()),
          if (_errorMessage.isNotEmpty) // Mostrar mensaje de error si hay uno
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
