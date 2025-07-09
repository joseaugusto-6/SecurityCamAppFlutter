// Archivo: lib/screens/face_management_screen.dart

import 'package:flutter/material.dart';
import 'package:my_first_app/services/api_service.dart';
import 'package:my_first_app/screens/face_registration_screen.dart';

class FaceManagementScreen extends StatefulWidget {
  const FaceManagementScreen({super.key});

  @override
  State<FaceManagementScreen> createState() => _FaceManagementScreenState();
}

class _FaceManagementScreenState extends State<FaceManagementScreen> {
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _namesFuture;

  Future<void> _confirmAndDeleteFace(String personName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            "¿Estás seguro de que quieres eliminar el rostro registrado de '$personName'? Esta acción no se puede deshacer.",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    // Si el usuario confirma, procedemos
    if (confirm == true) {
      try {
        await _apiService.deleteRegisteredFace(personName);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Rostro de '$personName' eliminado con éxito."),
            backgroundColor: Colors.green,
          ),
        );
        // Refrescamos la lista para que el nombre desaparecido se refleje en la UI
        _loadRegisteredNames();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRegisteredNames();
  }

  // Función para cargar o recargar los nombres
  void _loadRegisteredNames() {
    setState(() {
      _namesFuture = _apiService.getProfileSummary().then(
        (summary) => summary['registered_names'] ?? [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rostros Registrados'),
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 19, 195, 171),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _namesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar la lista: ${snapshot.error}'),
            );
          }

          final registeredNames = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Estas son las personas que tu sistema puede reconocer. Puedes añadir más perfiles faciales.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const Divider(height: 30),

                // Lista de nombres
                Expanded(
                  child: registeredNames.isEmpty
                      ? const Center(
                          child: Text(
                            'Aún no hay rostros registrados.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: registeredNames.length,
                          itemBuilder: (context, index) {
                            final personName = registeredNames[index]
                                .toString();
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  Icons.face_retouching_natural,
                                  color: Theme.of(context).primaryColor,
                                ),
                                title: Text(
                                  registeredNames[index].toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red[700],
                                  ),
                                  tooltip: 'Eliminar rostro',
                                  onPressed: () {
                                    _confirmAndDeleteFace(personName);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),

                // Botón para iniciar el registro
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Registrar Nuevo Rostro'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    // Navegamos a la pantalla de registro y esperamos a que vuelva
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceRegistrationScreen(),
                      ),
                    );
                    // Al volver, refrescamos la lista de nombres
                    _loadRegisteredNames();
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
