import 'package:flutter/material.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/widgets/event_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_first_app/screens/login_screen.dart'; // Para BASE_URL

class EventHistoryScreen extends StatefulWidget {
  const EventHistoryScreen({super.key});

  @override
  State<EventHistoryScreen> createState() => _EventHistoryScreenState();
}

class _EventHistoryScreenState extends State<EventHistoryScreen> {
  List<PersonEvent> _events = [];
  bool _isLoading = true;
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
        // Si no hay token, el usuario no está autenticado. Redirigir al login.
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

      final response = await http.get(
        Uri.parse(
          '$BASE_URL/events/history',
        ), // Tu endpoint de historial en Flask
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Enviar el token JWT
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> eventsJson = responseData['events'];

        setState(() {
          _events = eventsJson
              .map((json) => PersonEvent.fromJson(json))
              .toList();
        });
        _showSnackBar('Historial de eventos actualizado.', Colors.green);
      } else if (response.statusCode == 401) {
        // Token inválido o expirado
        await _secureStorage.delete(
          key: 'jwt_token',
        ); // Limpiar el token inválido
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        _showSnackBar(
          'Sesión expirada. Por favor, inicia sesión de nuevo.',
          Colors.red,
        );
      } else {
        // Otro error del servidor
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showSnackBar(
          errorData['msg'] ?? 'Error al cargar el historial.',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('Error de conexión: $e', Colors.red);
    } finally {
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
                return EventCard(event: _events[index]);
              },
            ),
    );
  }
}
