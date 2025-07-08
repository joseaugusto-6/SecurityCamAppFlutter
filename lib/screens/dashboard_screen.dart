import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_first_app/screens/event_history_screen.dart';
import 'package:my_first_app/screens/event_image_viewer_screen.dart';
import 'package:my_first_app/screens/face_registration_screen.dart';
import 'package:my_first_app/screens/notification_settings_screen.dart';
import 'package:my_first_app/screens/profile_settings_screen';
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('¿Cómo funciona esta App?'),

          // Dentro de AlertDialog, reemplaza la propiedad 'content' con esta:
          content: SingleChildScrollView(
            child: ListBody(
              // ListBody es ideal para listas dentro de diálogos
              children: <Widget>[
                const Text(
                  'Bienvenido a tu Sistema de Seguridad Inteligente.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Usamos RichText para combinar texto normal y en negrita
                RichText(
                  text: TextSpan(
                    // Estilo por defecto para este párrafo (toma el del tema actual)
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const <TextSpan>[
                      TextSpan(text: '• '),
                      TextSpan(
                        text: 'Última Alerta Crítica:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' Muestra la alerta más reciente que requiere tu atención.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const <TextSpan>[
                      TextSpan(text: '• '),
                      TextSpan(
                        text: 'Actividad Reciente:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' Aquí podrás ver los últimos eventos detectados por tus cámaras.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const <TextSpan>[
                      TextSpan(text: '• '),
                      TextSpan(
                        text: 'Video en Vivo:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' Si una cámara está en modo Stream, este botón te permitirá ver la transmisión.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const <TextSpan>[
                      TextSpan(text: '• '),
                      TextSpan(
                        text: 'Mis Cámaras:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            ' Visualiza y cambia el modo de funcionamiento de cada una de tus cámaras.',
                      ),
                    ],
                  ),
                ),

                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: const <TextSpan>[
                      TextSpan(text: '• '),
                      TextSpan(
                        text: 'Registrar Rostro:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'Registra una persona que quieras que tu sistema reconozca como "Conocida".',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Para más detalles, consulta la documentación completa.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Entendido',
                style: TextStyle(color: Color.fromARGB(255, 0, 9, 176)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
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
    // Caso 1: No hay ninguna alerta crítica. Muestra "Todo en calma".
    if (_latestAlert == null) {
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

    // Caso 2: SÍ hay una alerta. Muestra la tarjeta con imagen grande y botón funcional.
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.withOpacity(0.8)),
      ),
      clipBehavior:
          Clip.antiAlias, // Importante para que la imagen respete los bordes
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Título y Botón "Ver Historial" ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
            child: Row(
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
                const Spacer(),
                TextButton(
                  child: const Text('Ver Historial'),
                  onPressed: () {
                    // Esta es la navegación clave que pasa el ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventHistoryScreen(
                          highlightEventId:
                              _latestAlert!.id, // Le pasamos el ID de la alerta
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // --- Imagen Grande del Evento ---
          // --- CÓDIGO CORREGIDO (DESPUÉS) ---
          if (_latestAlert!.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 8.0),
              child: InkWell(
                // <-- 1. Envolvemos con InkWell para hacerlo clickable
                onTap: () {
                  // <-- 2. Añadimos la acción onTap
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 3. Navegamos a la pantalla del visor de imágenes
                      builder: (context) => EventImageViewerScreen(
                        imageUrl: _latestAlert!.imageUrl,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  // El ClipRRect ahora es el hijo del InkWell
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    _latestAlert!.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // --- Información del Evento (sin imagen en el leading) ---
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              _latestAlert!.personName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Cámara: ${_latestAlert!.deviceId}'),
            trailing: Text(
              _formatRelativeTime(_latestAlert!.timestamp),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    // Asegúrate de comparar con la hora local del dispositivo
    final difference = now.difference(timestamp.toLocal());

    if (difference.inDays > 0) {
      // Si ha pasado más de un día
      return 'Hace ${difference.inDays} día${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      // Si ha pasado más de una hora
      return 'Hace ${difference.inHours} hora${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      // Si ha pasado más de un minuto
      return 'Hace ${difference.inMinutes} min';
    } else {
      // Si acaba de ocurrir
      return 'Ahora mismo';
    }
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
      (d) =>
          (d['is_on'] ?? false) &&
          (d['is_active'] ?? false) &&
          d['mode'] == 'STREAMING_MODE',
    );
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(7, 0, 0, 0),
          child: Image.asset(
            'assets/images/logo.png', // <-- PON EL NOMBRE EXACTO DE TU ARCHIVO
          ),
        ),
        title: const Text(
          'AI Security Cam',
          style: TextStyle(color: Colors.white, fontSize: 30),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 19, 195, 171),
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.info_outline), // El ícono de información
            onPressed: () {
              // Aquí irá la lógica para mostrar la ayuda
              _showHelpDialog(context);
            },
          ),
        ],
      ),
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
                        onPressed: () async {
                          // <-- 1. Convertimos la función a async
                          // 2. Navegamos y ESPERAMOS a que el usuario regrese de la pantalla de dispositivos
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DeviceListScreen(),
                            ),
                          );
                          // 3. Justo cuando el usuario regresa, forzamos un refresco de los datos del dashboard
                          print(
                            "DEBUG: Regresando de DeviceListScreen, refrescando dashboard...",
                          );
                          _fetchDashboardData(isInitialLoad: false);
                        },
                      ),

                      _buildDashboardButton(
                        context,
                        title: 'Historial de Detecciones',
                        icon: Icons.history,
                        color: const Color.fromARGB(255, 11, 146, 173),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EventHistoryScreen(),
                            ),
                          );
                          // 3. Justo al regresar, refrescamos los datos del dashboard
                          _fetchDashboardData(isInitialLoad: false);
                        },
                      ),

                      _buildDashboardButton(
                        context,
                        title: 'Registrar Rostro', // <-- NUEVO BOTÓN
                        icon: Icons.face_retouching_natural,
                        color: Color.fromARGB(255, 19, 195, 171),
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

                  _buildDashboardButton(
                    context,
                    title: 'Notificaciones',
                    icon: Icons.notifications_active_outlined,
                    color: Colors.purple, // Un nuevo color para distinguirlo
                    onPressed: () {
                      // La misma navegación que tenía el botón anterior
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDashboardButton(
                    context,
                    title: 'Mi Perfil',
                    icon: Icons.person_outline,
                    color: const Color.fromARGB(
                      255,
                      5,
                      84,
                      230,
                    ), // Un nuevo color
                    onPressed: () {
                      // Navegará a la nueva pantalla que crearemos a continuación
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
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

                            // --- NUEVA VARIABLE PARA EL COLOR DEL TEXTO ---
                            Color subtitleColor;

                            String friendlyEventType;

                            switch (event.eventType) {
                              case 'known_person':
                                titleText = event.personName;
                                friendlyEventType = 'Acceso Registrado';
                                iconData = Icons.person_outline;
                                iconColor = Colors.green;
                                subtitleColor = Colors
                                    .green
                                    .shade700; // <-- Color para el texto
                                break;
                              case 'unknown_person':
                              case 'unknown_person_repeat':
                              case 'unknown_person_repeated_alarm':
                                titleText = 'Desconocido';
                                friendlyEventType = 'Alerta: Desconocido';
                                iconData = Icons.warning_amber;
                                iconColor = Colors.red;
                                subtitleColor = Colors
                                    .red
                                    .shade700; // <-- Color para el texto
                                break;
                              case 'alarm':
                                titleText = 'ALARMA';
                                friendlyEventType = 'Alarma Manual Activada';
                                iconData = Icons.notifications_active;
                                iconColor = Colors.orange;
                                subtitleColor = Colors
                                    .orange
                                    .shade800; // <-- Color para el texto
                                break;
                              default:
                                titleText = 'Evento';
                                friendlyEventType = event.eventType;
                                iconData = Icons.info_outline;
                                iconColor = Colors.grey;
                                subtitleColor = Colors
                                    .grey
                                    .shade700; // <-- Color para el texto
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
                                      )
                                    : CircleAvatar(
                                        // AHORA SÍ USAMOS iconData y iconColor
                                        radius: 25,
                                        backgroundColor: iconColor.withOpacity(
                                          0.2,
                                        ),
                                        child: Icon(iconData, color: iconColor),
                                      ),
                                title: Text(
                                  titleText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // --- INICIO DEL CAMBIO A RICHTEXT ---
                                subtitle: RichText(
                                  text: TextSpan(
                                    // Estilo por defecto para el subtítulo (el que usa la hora)
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    children: <TextSpan>[
                                      // Primer fragmento de texto: el tipo de evento con su color
                                      TextSpan(
                                        text: friendlyEventType,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              subtitleColor, // <-- Usamos el color dinámico
                                        ),
                                      ),
                                      // Segundo fragmento de texto: la hora, con el color por defecto
                                      TextSpan(
                                        text:
                                            ' - ${DateFormat('h:mm a').format(event.timestamp.toLocal())}',
                                      ),
                                    ],
                                  ),
                                ),
                                // --- FIN DEL CAMBIO A RICHTEXT ---

                                // --- AÑADE ESTE NUEVO WIDGET ---
                                trailing: Icon(
                                  iconData, // Reutilizamos el ícono que ya definimos en el switch
                                  color:
                                      iconColor, // Reutilizamos el color que ya definimos
                                  size: 28, // Un tamaño adecuado
                                ),
                                // ---------------------------------
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

                  const SizedBox(height: 40),

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
                  const SizedBox(height: 40),
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
