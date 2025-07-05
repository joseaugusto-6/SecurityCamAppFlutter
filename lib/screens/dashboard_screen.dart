import 'package:flutter/material.dart';
import 'package:my_first_app/screens/event_history_screen.dart';
import 'package:my_first_app/services/auth_service.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/services/api_service.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/screens/device_list_screen.dart';
import 'package:my_first_app/screens/live_stream_screen.dart'; // <-- ¡Añade esta importación para la nueva pantalla!

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalEntriesToday = 0;
  int _alarmsToday = 0;
  List<PersonEvent> _latestEvents = [];
  bool _isLoadingDashboard = true;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
    });
    try {
      final data = await _apiService.getDashboardData();
      setState(() {
        _latestEvents = data['latest_events'];
        _totalEntriesToday = data['total_entries_today'];
        _alarmsToday = data['alarms_today'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos del dashboard: $e'),
          backgroundColor: Colors.red,
        ),
      );
      if (e.toString().contains('Authentication failed')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } finally {
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar tu sesión?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _authService.deleteJwtToken();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Seguridad'),
        actions: [
          // Botón de Video en Vivo - NUEVO
          IconButton(
            icon: const Icon(Icons.videocam), // Icono de cámara de video
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LiveStreamScreen(),
                ), // Navega a la pantalla de video
              );
            },
            tooltip: 'Video en Vivo',
          ),
          // Botón de Mis Cámaras/Dispositivos
          IconButton(
            icon: const Icon(Icons.devices),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeviceListScreen(),
                ),
              );
            },
            tooltip: 'Mis Cámaras/Dispositivos',
          ),
          // Botón de Historial de Eventos
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EventHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historial de Eventos',
          ),
          // Botón de Cerrar Sesión
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Resumen Diario',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Entradas Hoy:',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_totalEntriesToday',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Alarmas Hoy:',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$_alarmsToday',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Actividad Reciente',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _latestEvents.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay actividad reciente para mostrar.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _latestEvents.length,
                            itemBuilder: (context, index) {
                              final event = _latestEvents[index];
                              String titleText;
                              IconData iconData;
                              Color iconColor;

                              switch (event.eventType) {
                                case 'known_person':
                                  titleText = event.personName;
                                  iconData = Icons.person_outline;
                                  iconColor = Colors.green;
                                  break;
                                case 'unknown_person':
                                  titleText = 'Desconocido';
                                  iconData = Icons.warning_amber;
                                  iconColor = Colors.red;
                                  break;
                                case 'alarm':
                                  titleText = 'ALARMA';
                                  iconData = Icons.notifications_active;
                                  iconColor = Colors.orange;
                                  break;
                                default:
                                  titleText = 'Evento';
                                  iconData = Icons.info_outline;
                                  iconColor = Colors.grey;
                                  break;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                elevation: 2,
                                child: ListTile(
                                  leading: event.imageUrl.isNotEmpty
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            event.imageUrl,
                                          ),
                                          radius: 25,
                                          backgroundColor: Colors.grey[200],
                                          onBackgroundImageError:
                                              (exception, stackTrace) {
                                                print(
                                                  'Error loading image: $exception',
                                                );
                                              },
                                        )
                                      : CircleAvatar(
                                          child: Icon(
                                            iconData,
                                            color: iconColor,
                                          ),
                                          radius: 25,
                                          backgroundColor: iconColor
                                              .withOpacity(0.2),
                                        ),
                                  title: Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${event.eventType} - ${event.timestamp.toLocal().toString().split('.')[0]}',
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EventHistoryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
