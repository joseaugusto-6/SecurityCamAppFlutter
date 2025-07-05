import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Para abrir URLs externas
import 'package:my_first_app/services/api_service.dart'; // Para obtener el token de sesión
import 'package:my_first_app/screens/login_screen.dart'; // Para redirigir en caso de fallo de autenticación

// URL base de la página web que incrusta el stream
const String WEB_STREAM_BASE_URL =
    'https://tesisdeteccion.ddns.net/live_stream'; // ¡ACTUALIZA ESTO!

class LiveStreamScreen extends StatefulWidget {
  final String cameraId; // El ID de la cámara que esta pantalla va a mostrar

  const LiveStreamScreen({
    super.key,
    required this.cameraId,
  }); // Constructor para recibir el camera_id

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> {
  String _statusMessage = 'Preparando stream...';
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _prepareAndLaunchStream(); // Inicia el proceso para obtener token y lanzar la URL
  }

  Future<void> _prepareAndLaunchStream() async {
    setState(() {
      _isLoading = true;
      _statusMessage =
          'Obteniendo token de sesión para la cámara ${widget.cameraId}...';
    });

    try {
      // 1. Obtener el token de sesión del stream desde el backend
      final Map<String, dynamic> sessionData = await _apiService
          .getStreamSessionToken(widget.cameraId);
      final String sessionToken = sessionData['session_token'];

      // 2. Construir la URL completa con los parámetros de la cámara y el token
      final Uri streamUrl = Uri.parse(
        '$WEB_STREAM_BASE_URL?camera_id=${widget.cameraId}&session_token=$sessionToken',
      );

      // 3. Lanzar la URL en el navegador externo
      setState(() {
        _statusMessage = 'Abriendo stream en navegador...';
        _isLoading = false;
      });

      if (!await launchUrl(streamUrl, mode: LaunchMode.externalApplication)) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Error: No se pudo abrir el stream en el navegador.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: No se pudo abrir el stream en el navegador: $streamUrl',
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Si la URL se lanza con éxito, la pantalla principal de la app ya no necesita un cargador
        // El usuario ahora interactuará con el navegador.
        if (!mounted) return;
        // Opcional: Cerrar esta pantalla de Flutter si quieres que el navegador sea la única vista.
        // Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage =
            'Error al preparar el stream: ${e.toString()}. Por favor, intente de nuevo.';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      // Si el error indica fallo de autenticación, redirigir al login
      if (e.toString().contains('Authentication failed')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video en Vivo (Web)'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _prepareAndLaunchStream, // Reintentar abrir la URL
            tooltip: 'Abrir en Navegador',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (!_isLoading) // Mostrar botón de reintentar solo si no está cargando
              ElevatedButton(
                onPressed: _prepareAndLaunchStream,
                child: const Text('Reintentar'),
              ),
          ],
        ),
      ),
    );
  }
}
