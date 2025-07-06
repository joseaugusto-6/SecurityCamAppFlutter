import 'package:flutter/material.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/widgets/event_card.dart'; // Asegúrate de que EventCard esté importado
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/screens/event_image_viewer_screen.dart'; // Importa el visor de imágenes
import 'package:my_first_app/services/api_service.dart'; // Para BASE_URL

// Aquí puedes mantener BASE_URL si no quieres depender de ApiService para esto
// const String BASE_URL = 'https://tesisdeteccion.ddns.net/api';

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  List<PersonEvent> _events = [];
  bool _isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final ApiService _apiService = ApiService(); // Para acceder a BASE_URL

  @override
  void initState() {
    super.initState();
    _fetchEvents(); // Cargar eventos al iniciar la pantalla
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String? token = await _secureStorage.read(key: 'jwt_token');

      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        _showSnackBar(
          'Sesión expirada o no iniciada. Por favor, inicia sesión de nuevo.',
          Colors.red,
        );
        return;
      }

      // Usa ApiService.BASE_URL para mayor consistencia
      final response = await http.get(
        Uri.parse(
          '${ApiService.BASE_URL}/events/history',
        ), // <-- CAMBIO CLAVE AQUÍ: Usar ApiService.BASE_URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> eventsJson = responseData['events'];

        if (!mounted) return;
        setState(() {
          _events = eventsJson
              .map((json) => PersonEvent.fromJson(json))
              .toList();
        });
        _showSnackBar('Historial de eventos actualizado.', Colors.green);
      } else if (response.statusCode == 401) {
        await _secureStorage.delete(key: 'jwt_token');
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        _showSnackBar(
          'Sesión expirada. Por favor, inicia sesión de nuevo.',
          Colors.red,
        );
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showSnackBar(
          errorData['msg'] ?? 'Error al cargar el historial.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error de conexión: ${e.toString()}', Colors.red);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Eventos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEvents, // Botón para refrescar el historial
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
          ? const Center(
              child: Text(
                'No hay eventos registrados aún.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return EventCard(
                  // Pasa la función onTap al EventCard
                  event: event,
                  onTap: () {
                    // <-- ¡onTap que abre el visor de imágenes!
                    if (event.imageUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EventImageViewerScreen(imageUrl: event.imageUrl),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No hay imagen disponible para este evento.',
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
