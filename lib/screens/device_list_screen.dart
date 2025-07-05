import 'package:flutter/material.dart';
import 'package:my_first_app/services/api_service.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/screens/live_stream_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => DeviceListScreenState();
}

class DeviceListScreenState extends State<DeviceListScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUserDevices();
  }

  Future<void> _fetchUserDevices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      _devices = await _apiService.getUserDevices();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar dispositivos: ${e.toString()}';
          _isLoading = false;
        });
        if (e.toString().contains('Authentication failed')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  // FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE AÑADIR DISPOSITIVO
  Future<void> _showAddDeviceDialog() async {
    // <-- Esta función debe estar aquí
    String? newDeviceId;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Añadir Nuevo Dispositivo'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Introduce el ID único del dispositivo (ej. camera001):',
                ),
                TextField(
                  onChanged: (value) {
                    newDeviceId = value;
                  },
                  decoration: const InputDecoration(
                    hintText: "ID del Dispositivo",
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Añadir'),
              onPressed: () async {
                if (newDeviceId != null && newDeviceId!.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _addDevice(newDeviceId!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Por favor, introduce un ID de dispositivo.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // FUNCIÓN PARA LLAMAR AL BACKEND Y AÑADIR EL DISPOSITIVO
  Future<void> _addDevice(String deviceId) async {
    // <-- Esta función debe estar aquí
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await _apiService.addDevice(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispositivo $deviceId añadido correctamente.'),
          ),
        );
      }
      await _fetchUserDevices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al añadir dispositivo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        if (e.toString().contains('Authentication failed')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // FUNCIÓN PARA MOSTRAR EL DIÁLOGO DE CONFIRMACIÓN ANTES DE ELIMINAR
  Future<void> _removeDeviceConfirm(String deviceId) async {
    // <-- Esta función debe estar aquí
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Dispositivo'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el dispositivo "$deviceId"?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _removeDevice(deviceId);
    }
  }

  // FUNCIÓN PARA LLAMAR AL BACKEND Y ELIMINAR EL DISPOSITIVO
  Future<void> _removeDevice(String deviceId) async {
    // <-- Esta función debe estar aquí
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await _apiService.removeDevice(deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dispositivo $deviceId eliminado correctamente.'),
          ),
        );
      }
      await _fetchUserDevices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar dispositivo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        if (e.toString().contains('Authentication failed')) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // FUNCIÓN PARA ENVIAR COMANDO DE CAMBIO DE MODO
  Future<void> _setCameraMode(String deviceId, String mode) async {
    // Guardar el estado actual del dispositivo para posible revertir
    final int deviceIndex = _devices.indexWhere((d) => d['id'] == deviceId);
    if (deviceIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Dispositivo no encontrado en la lista.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> oldDeviceState = Map.from(
      _devices[deviceIndex],
    ); // Copia del estado antiguo
    final String oldMode = oldDeviceState['mode'] as String;

    // 1. Actualización optimista de la UI
    if (mounted) {
      setState(() {
        _devices[deviceIndex]['mode'] =
            mode; // Actualiza el modo en la lista local
        _isLoading =
            false; // Asumimos que la UI no está "cargando" por el cambio de modo
        _errorMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        // Mensaje de que el comando fue enviado
        SnackBar(
          content: Text(
            'Comando "$mode" enviado a $deviceId (actualizando UI).',
          ),
          backgroundColor: Colors.grey[700],
        ),
      );
    }

    String message = '';
    Color color = Colors.green;

    try {
      // 2. Enviar el comando al backend
      await _apiService.setCameraMode(deviceId, mode);
      message = 'Comando "$mode" ejecutado en $deviceId.';
      color = Colors.green;
    } catch (e) {
      // 3. Si hay un error, revertir la UI y mostrar mensaje de error
      message = 'Error al enviar comando: ${e.toString()}';
      color = Colors.red;
      if (mounted) {
        // Revertir solo si el widget sigue montado
        setState(() {
          _devices[deviceIndex]['mode'] = oldMode; // Revertir al modo anterior
        });
      }
      if (e.toString().contains('Authentication failed')) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        // Mostrar mensaje final de éxito/error de la operación remota
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
        // Opcional: _fetchUserDevices(); para reconciliar el estado con el servidor
        // Lo quitamos para evitar flickering, ya que la actualización optimista es suficiente.
        // Si el estado real es muy importante, un timer de refresco en la DeviceListScreen sería mejor.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cámaras/Dispositivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddDeviceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(_errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchUserDevices,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : _devices.isEmpty
          ? const Center(
              child: Text(
                'No tienes dispositivos registrados aún. Pulsa el botón "+" para añadir uno.',
              ),
            )
          : ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index]; // <-- Ahora 'device' es un Map
                final deviceId =
                    device['id'] as String; // Obtener el ID de la cámara
                final currentMode =
                    device['mode'] as String; // Obtener el modo actual
                final isActive =
                    device['is_active'] as bool; // Obtener si está activa

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            isActive
                                ? Icons.camera_alt
                                : Icons
                                      .highlight_off, // <-- Ícono para "offline"
                            color: isActive
                                ? Colors.green
                                : Colors.grey, // Indicador de activo/inactivo
                          ),
                          title: Text('Dispositivo ID: $deviceId'),
                          // Subtítulo con el modo actual
                          subtitle: Text(
                            'Modo: $currentMode ${isActive ? '(Online)' : '(Offline)'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.videocam,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LiveStreamScreen(cameraId: deviceId),
                                    ),
                                  );
                                },
                                tooltip: 'Ver Stream',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeDeviceConfirm(deviceId),
                                tooltip: 'Eliminar Dispositivo',
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // ---------- BOTÓN STREAM ----------
                            Expanded(
                              child: SizedBox(
                                height: currentMode == "STREAMING_MODE"
                                    ? 60
                                    : 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _setCameraMode(
                                    deviceId,
                                    "STREAMING_MODE",
                                  ), // <-- aquí el mismo texto
                                  icon: const Icon(Icons.videocam_outlined),
                                  label: const Text('Modo Stream'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        currentMode == "STREAMING_MODE"
                                        ? const Color.fromARGB(
                                            255,
                                            0,
                                            174,
                                            255,
                                          ) // seleccionado
                                        : const Color.fromARGB(
                                            255,
                                            48,
                                            63,
                                            159,
                                          ), // no seleccionado
                                    foregroundColor: Colors.white,
                                    padding: currentMode == "STREAMING_MODE"
                                        ? const EdgeInsets.symmetric(
                                            vertical: 20,
                                          )
                                        : const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                    textStyle: TextStyle(
                                      fontSize: currentMode == "STREAMING_MODE"
                                          ? 18
                                          : 16,
                                      fontWeight:
                                          currentMode == "STREAMING_MODE"
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    elevation: currentMode == "STREAMING_MODE"
                                        ? 8
                                        : 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ---------- BOTÓN CAPTURA ----------
                            Expanded(
                              child: SizedBox(
                                height: currentMode == "CAPTURE_MODE" ? 60 : 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _setCameraMode(
                                    deviceId,
                                    "CAPTURE_MODE",
                                  ), // <-- igual que arriba
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Modo Captura'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        currentMode == "CAPTURE_MODE"
                                        ? const Color.fromARGB(255, 0, 174, 255)
                                        : Colors.indigo[700],
                                    foregroundColor: Colors.white,
                                    padding: currentMode == "CAPTURE_MODE"
                                        ? const EdgeInsets.symmetric(
                                            vertical: 20,
                                          )
                                        : const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                    textStyle: TextStyle(
                                      fontSize: currentMode == "CAPTURE_MODE"
                                          ? 18
                                          : 16,
                                      fontWeight: currentMode == "CAPTURE_MODE"
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    elevation: currentMode == "CAPTURE_MODE"
                                        ? 8
                                        : 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
