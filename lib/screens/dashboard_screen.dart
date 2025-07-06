import 'package:flutter/material.dart';
import 'package:my_first_app/screens/event_history_screen.dart';
import 'package:my_first_app/services/auth_service.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/services/api_service.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/screens/device_list_screen.dart';
import 'package:my_first_app/screens/live_stream_screen.dart';
import 'dart:async'; // <-- ¡Añade esta importación para Timer!

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
  Timer? _timer; // <-- Variable para el Timer

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    // Iniciar un timer para recargar el dashboard cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchDashboardData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el timer cuando el widget se destruye
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
    });
    try {
      final data = await _apiService.getDashboardData();
      if (!mounted) return;
      setState(() {
        _latestEvents = data['latest_events'];
        _totalEntriesToday = data['total_entries_today'];
        _alarmsToday = data['alarms_today'];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos del dashboard: ${e.toString()}'),
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
      if (!mounted) return;
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
      if (!mounted) return;
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
        // Eliminamos los actions de aquí, los botones estarán en el body
        // actions: [ ... ]
      ),
      body: _isLoadingDashboard
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Botones de Navegación Grandes - NUEVOS EN EL BODY
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildDashboardButton(
                        context,
                        title: 'Video en Vivo',
                        icon: Icons.videocam,
                        color: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LiveStreamScreen(cameraId: 'camera001'),
                            ),
                          );
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: 'Mis Cámaras',
                        icon: Icons.devices,
                        color: Colors.green,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DeviceListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: 'Historial',
                        icon: Icons.history,
                        color: Colors.orange,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EventHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardButton(
                        context,
                        title: 'Cerrar Sesión',
                        icon: Icons.logout,
                        color: Colors.red,
                        onPressed: _logout,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Sección de Estadísticas Rápidas (Resumen Diario)
                  const Text(
                    'Resumen Diario',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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

                  // Sección de Actividad Reciente
                  const Text(
                    'Actividad Reciente',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _latestEvents.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay actividad reciente para mostrar.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                          color: iconColor.withAlpha(
                                            (0.2 * 255).round(),
                                          ),
                                        ),
                                        radius: 25,
                                        backgroundColor: iconColor.withOpacity(
                                          0.2,
                                        ),
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
    );
  }

  // Función auxiliar para construir los botones grandes del dashboard
  Widget _buildDashboardButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
