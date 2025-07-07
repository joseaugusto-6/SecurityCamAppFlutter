import 'package:flutter/material.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/widgets/event_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/screens/event_image_viewer_screen.dart';
import 'package:my_first_app/services/api_service.dart'; // Asegúrate de que ApiService esté importado

class EventHistoryScreen extends StatefulWidget {
  final String? highlightEventId;
  const EventHistoryScreen({super.key, this.highlightEventId});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  List<PersonEvent> _events = [];
  bool _isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
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

      // Usamos ApiService.BASE_URL para mayor consistencia
      final response = await http.get(
        Uri.parse('${ApiService.BASE_URL}/events/history'),
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
        _showSnackBar('Historial de detecciones actualizado.', Colors.green);
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

  Future<void> _confirmAndClearHistory() async {
    // 1. Mostrar un diálogo de confirmación antes de borrar
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Borrado'),
          content: const Text(
            '¿Estás seguro de que quieres eliminar TODOS los eventos del historial? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Devuelve false
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Devuelve true
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    // 2. Si el usuario no confirma (devuelve null o false), no hacemos nada
    if (confirm != true) {
      return;
    }

    // 3. Si el usuario confirma, procedemos con el borrado
    setState(() {
      _isLoading = true;
    }); // Mostrar indicador de carga

    try {
      final result = await _apiService.clearEventHistory();
      if (!mounted) return;

      // Mostrar el mensaje de éxito que viene del servidor
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['msg'] ?? 'Historial eliminado.'),
          backgroundColor: Colors.green,
        ),
      );

      // Volver a cargar la lista de eventos (que ahora estará vacía)
      await _fetchEvents();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al limpiar el historial: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Ocultar el indicador de carga, tanto si hubo éxito como si hubo error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        title: const Text('Historial'),
        backgroundColor: Color.fromARGB(255, 11, 146, 173),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpiar historial',
            onPressed: _confirmAndClearHistory, // Llama a la nueva función
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchEvents),
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
                  event: event,
                  isHighlighted: event.id == widget.highlightEventId,
                  onTap: () {
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
