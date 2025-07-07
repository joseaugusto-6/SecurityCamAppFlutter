import 'dart:async';

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

  // --- NUEVO: Timer para el auto-refresco ---
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Hacemos la primera carga inmediatamente
    _fetchUserDevices(isInitialLoad: true);
    // Iniciamos el refresco automático
    _startAutoRefresh();
  }

  // --- NUEVO: Función para iniciar el Timer ---
  void _startAutoRefresh() {
    // Cada 10 segundos, llamará a _fetchUserDevices en segundo plano
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchUserDevices(); // No es carga inicial, será silencioso
    });
  }

  // --- IMPORTANTE: Detener el Timer al salir de la pantalla ---
  @override
  void dispose() {
    _timer?.cancel(); // Detiene el timer para evitar errores y fugas de memoria
    super.dispose();
  }

  Future<void> _fetchUserDevices({bool isInitialLoad = false}) async {
    // Solo mostramos el indicador de carga la primera vez
    if (isInitialLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final freshDevices = await _apiService.getUserDevices();
      if (mounted) {
        setState(() {
          _devices = freshDevices;
          // Solo si fue carga inicial, quitamos el indicador
          if (isInitialLoad) {
            _isLoading = false;
          }
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

    final Map<String, dynamic> oldDeviceState = Map.from(_devices[deviceIndex]);
    final String oldMode = oldDeviceState['mode'] as String;

    if (mounted) {
      setState(() {
        _devices[deviceIndex] = Map<String, dynamic>.from(oldDeviceState)
          ..['mode'] = mode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
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
      await _apiService.setCameraMode(deviceId, mode);
      message = 'Comando "$mode" ejecutado en $deviceId.';
      color = Colors.green;
    } catch (e) {
      message = 'Error al enviar comando: ${e.toString()}';
      color = Colors.red;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
      }
    }
  }

  // NUEVA FUNCIÓN: Para enviar comando de encendido/apagado
  Future<void> _toggleCameraPower(String deviceId, bool isOn) async {
    final String powerState = isOn ? "ON" : "OFF";
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

    final Map<String, dynamic> oldDeviceState = Map.from(_devices[deviceIndex]);
    final bool oldPowerState = oldDeviceState['is_on'] as bool;

    // Actualización optimista de la UI
    if (mounted) {
      setState(() {
        _devices[deviceIndex] = Map<String, dynamic>.from(_devices[deviceIndex])
          ..['is_on'] = isOn;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comando "Power $powerState" enviado a $deviceId (actualizando UI).',
          ),
          backgroundColor: Colors.grey[700],
        ),
      );
    }

    String message = '';
    Color color = Colors.green;

    try {
      await _apiService.setCameraPower(deviceId, powerState);
      message = 'Comando "Power $powerState" ejecutado en $deviceId.';
    } catch (e) {
      message = 'Error al enviar comando: ${e.toString()}';
      color = Colors.red;
      // Revertir UI si hay error
      if (mounted) {
        setState(() {
          _devices[deviceIndex] = Map<String, dynamic>.from(oldDeviceState);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cámaras'),
        backgroundColor: Color.fromARGB(255, 8, 25, 122),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                final device = _devices[index];
                final deviceId = device['id'] as String;
                final currentMode = device['mode'] as String;
                final isActive = device['is_active'] as bool;
                final isOn = device['is_on'] as bool;

                return Card(
                  key: ValueKey(deviceId),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            isActive ? Icons.camera_alt : Icons.highlight_off,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                          title: Text('ID: $deviceId'),
                          subtitle: Text(
                            'Modo: ${currentMode == 'STREAMING_MODE'
                                ? 'Streaming'
                                : currentMode == 'CAPTURE_MODE'
                                ? 'Captura'
                                : currentMode == ''} ${isActive ? '(Online)' : '(Offline)'}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeDeviceConfirm(deviceId),
                            tooltip: 'Eliminar Dispositivo',
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // ----------- STREAMING -----------
                            Expanded(
                              child: SizedBox(
                                height: currentMode == "STREAMING_MODE"
                                    ? 60
                                    : 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => _setCameraMode(
                                    deviceId,
                                    "STREAMING_MODE",
                                  ),
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

                            // ------------- CAPTURA -------------
                            Expanded(
                              child: SizedBox(
                                height: currentMode == "CAPTURE_MODE" ? 60 : 48,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _setCameraMode(deviceId, "CAPTURE_MODE"),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Modo Captura'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        currentMode == "CAPTURE_MODE"
                                        ? const Color.fromARGB(
                                            255,
                                            0,
                                            174,
                                            255,
                                          ) // seleccionado
                                        : Colors.indigo[700], // no seleccionado
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
                        const SizedBox(height: 10),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text('On/Off'),
                            const SizedBox(width: 10),
                            Switch.adaptive(
                              value: isOn,
                              onChanged: isActive
                                  ? (bool newValue) {
                                      _toggleCameraPower(deviceId, newValue);
                                    }
                                  : null,
                              activeColor: Colors.teal,
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
