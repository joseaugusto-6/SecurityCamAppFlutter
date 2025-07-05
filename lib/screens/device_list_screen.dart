import 'package:flutter/material.dart';
import 'package:my_first_app/services/api_service.dart'; // Importa ApiService
import 'package:my_first_app/screens/login_screen.dart'; // Importa LoginScreen

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key}); // Constructor correcto con key

  @override
  // Eliminado el '_' para hacer la clase pública (soluciona library_private_types_in_public_api)
  State<DeviceListScreen> createState() => DeviceListScreenState();
}

// Eliminado el '_' para hacer la clase pública
class DeviceListScreenState extends State<DeviceListScreen> {
  List<String> _devices = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final ApiService _apiService = ApiService(); // Instancia de ApiService

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
      _devices = await _apiService
          .getUserDevices(); // Llama al método correcto en ApiService
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar dispositivos: ${e.toString()}';
        _isLoading = false;
      });
      // Si el error indica fallo de autenticación, redirigir al login
      if (e.toString().contains('Authentication failed')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // Función para mostrar el diálogo de añadir dispositivo
  Future<void> _showAddDeviceDialog() async {
    String? newDeviceId;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe pulsar un botón
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
                  Navigator.of(context).pop(); // Cerrar diálogo
                  await _addDevice(
                    newDeviceId!,
                  ); // Llamar a la función para añadir
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

  // Función para llamar al backend y añadir el dispositivo
  Future<void> _addDevice(String deviceId) async {
    setState(() {
      _isLoading = true; // Mostrar indicador de carga mientras se añade
      _errorMessage = '';
    });
    try {
      await _apiService.addDevice(deviceId); // Llama a la API real
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispositivo $deviceId añadido correctamente.')),
      );
      await _fetchUserDevices(); // Recargar la lista de dispositivos después de añadir
    } catch (e) {
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
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para mostrar el diálogo de confirmación antes de eliminar
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ), // Botón rojo para eliminar
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _removeDevice(deviceId); // Llama a la función de eliminación real
    }
  }

  // Función para llamar al backend y eliminar el dispositivo
  Future<void> _removeDevice(String deviceId) async {
    setState(() {
      _isLoading = true; // Mostrar indicador de carga
      _errorMessage = '';
    });
    try {
      await _apiService.removeDevice(deviceId); // Llama a la API real
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispositivo $deviceId eliminado correctamente.'),
        ),
      );
      await _fetchUserDevices(); // Recargar la lista después de eliminar
    } catch (e) {
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
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                final deviceId = _devices[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: Text('Dispositivo ID: $deviceId'),
                    subtitle: const Text('Estado: Conectado (simulado)'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeDeviceConfirm(
                        deviceId,
                      ), // Llama a la confirmación
                    ),
                  ),
                );
              },
            ),
    );
  }
}
