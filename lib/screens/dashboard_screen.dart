import 'package:flutter/material.dart';
import 'package:my_first_app/screens/event_history_screen.dart';
import 'package:my_first_app/screens/face_registration_screen.dart';
import 'package:my_first_app/services/auth_service.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/services/api_service.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/screens/device_list_screen.dart';
import 'package:my_first_app/screens/live_stream_screen.dart';

import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<PersonEvent> _latestEvents = [];
  PersonEvent? _latestAlert;
  List<Map<String, dynamic>> _devices = [];
  bool _isLoadingDashboardInitial = true;
  Timer? _timer;
  final int _refreshIntervalSeconds = 15;

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchDashboardData(isInitialLoad: true);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: _refreshIntervalSeconds), (
      timer,
    ) {
      _fetchDashboardData(isInitialLoad: false);
    });
  }

  void _handleLiveStreamNavigation() {
    // 1. Filtramos la lista para encontrar solo las cámaras que están ON y ONLINE
    final onlineCameras = _devices.where((d) {
      final bool isOn = d['is_on'] ?? false;
      final bool isActive = d['is_active'] ?? false;
      return isOn && isActive;
    }).toList();

    // 2. Decidimos qué hacer según cuántas cámaras disponibles haya
    if (onlineCameras.isEmpty) {
      // No debería pasar porque el botón estará deshabilitado, pero es una buena práctica
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No hay cámaras disponibles para el stream en este momento.',
          ),
        ),
      );
      return;
    }

    if (onlineCameras.length == 1) {
      // Si solo hay una, vamos directamente a ella
      final cameraId = onlineCameras.first['id'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamScreen(cameraId: cameraId),
        ),
      );
    } else {
      // Si hay varias, mostramos un diálogo para que el usuario elija
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text('Seleccionar Cámara'),
            children: onlineCameras.map((camera) {
              return SimpleDialogOption(
                onPressed: () {
                  final cameraId = camera['id'];
                  Navigator.of(context).pop(); // Cierra el diálogo
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LiveStreamScreen(cameraId: cameraId),
                    ),
                  );
                },
                child: Text('Cámara: ${camera['id']}'),
              );
            }).toList(),
          );
        },
      );
    }
  }

  Widget _buildLatestAlertCard() {
    if (_latestAlert == null) {
      // Si no hay alertas, mostramos un mensaje tranquilizador
      return Card(
        elevation: 2,
        color: Colors.green[50],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.green.withOpacity(0.5)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
              SizedBox(width: 15),
              Text(
                'Todo en calma',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Si SÍ hay una alerta, mostramos la tarjeta de advertencia
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.withOpacity(0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Última Alerta Crítica',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 20),
            ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(_latestAlert!.imageUrl),
              ),
              title: Text(
                _latestAlert!.personName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _latestAlert!.eventType.replaceAll('_', ' ').toUpperCase(),
              ),
              trailing: Text(
                // Lógica simple para mostrar "hace X tiempo"
                'Hace ${DateTime.now().difference(_latestAlert!.timestamp.toLocal()).inMinutes} min',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchDashboardData({required bool isInitialLoad}) async {
    if (isInitialLoad) {
      setState(() {
        _isLoadingDashboardInitial = true;
      });
    }

    try {
      // --- AÑADIMOS LA LLAMADA PARA OBTENER LOS DISPOSITIVOS ---
      // Hacemos las llamadas en paralelo para más eficiencia
      final results = await Future.wait([
        _apiService.getDashboardData(),
        _apiService.getLatestAlert(),
        _apiService.getUserDevices(), // <-- NUEVA LLAMADA
      ]);

      // Extraemos los resultados
      final dashboardData = results[0] as Map<String, dynamic>;
      _latestAlert = results[1] as PersonEvent?;
      _devices =
          results[2]
              as List<Map<String, dynamic>>; // <-- GUARDAMOS LOS DISPOSITIVOS

      if (!mounted) return;
      setState(() {
        // Actualizamos el estado con los datos del dashboard
        _latestEvents = dashboardData['latest_events'];
      });
    } catch (e) {
      if (!mounted) return;
      if (isInitialLoad || e.toString().contains('Authentication failed')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar datos del dashboard: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (e.toString().contains('Authentication failed')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } finally {
      if (isInitialLoad && mounted) {
        setState(() {
          _isLoadingDashboardInitial = false;
        });
      }
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
    final bool isAnyCameraAvailableForStream = _devices.any(
      (d) => (d['is_on'] ?? false) && (d['is_active'] ?? false),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard de Seguridad')),
      body: _isLoadingDashboardInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Sección de Estadísticas Rápidas (Resumen Diario)
                  const Text(
                    'Estado del Sistema',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  _buildLatestAlertCard(),

                  const SizedBox(height: 30),

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
                        // El color cambia si el botón está deshabilitado
                        color: isAnyCameraAvailableForStream
                            ? Colors.blue
                            : Colors.grey,
                        // La acción es nuestra nueva función si está disponible, o null si no lo está (lo deshabilita)
                        onPressed: isAnyCameraAvailableForStream
                            ? _handleLiveStreamNavigation
                            : null,
                      ),
                      _buildDashboardButton(
                        context,
                        title: 'Mis Cámaras',
                        icon: Icons.devices,
                        color: const Color.fromARGB(255, 8, 25, 122),
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
                        title: 'Historial de Detecciones',
                        icon: Icons.history,
                        color: const Color.fromARGB(255, 0, 234, 211),
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
                        title: 'Registrar Rostro', // <-- NUEVO BOTÓN
                        icon: Icons.face_retouching_natural,
                        color: Colors.teal, // O el color que prefieras
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const FaceRegistrationScreen(),
                            ),
                          );
                        },
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
                                              debugPrint(
                                                'Error loading image: $exception',
                                              ); // Usar debugPrint
                                            },
                                      )
                                    : CircleAvatar(
                                        radius: 25,
                                        backgroundColor: iconColor.withOpacity(
                                          0.2,
                                        ),
                                        child: Icon(
                                          iconData,
                                          color: iconColor.withAlpha(
                                            (0.2 * 255).round(),
                                          ),
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

                  const SizedBox(
                    height: 40,
                  ), // Un buen espacio para separar de la lista de arriba

                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    onPressed:
                        _logout, // Reutilizamos la misma función _logout que ya existe
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        44,
                      ), // Esto lo hace bastante ancho y con una altura fija
                      foregroundColor: Colors.red, // Color del texto y el ícono
                      side: const BorderSide(
                        color: Colors.red,
                      ), // Color del borde
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Bordes redondeados
                      ),
                    ),
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
    required VoidCallback? onPressed,
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
              Icon(icon, size: 30, color: Colors.white),
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
