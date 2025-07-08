// Archivo: lib/screens/face_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:my_first_app/services/api_service.dart';

// Enum para controlar el flujo de la UI
enum RegistrationStep {
  instructions,
  nameInput,
  capturing,
  uploading,
  completed,
}

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});

  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> {
  // --- VARIABLES DE ESTADO ---
  RegistrationStep _currentStep = RegistrationStep.instructions;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  final List<XFile> _capturedImages = [];
  final int _captureGoal = 15;
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _completionMessage = '';
  String _errorMessage = '';

  // --- CICLO DE VIDA DEL WIDGET ---
  @override
  void dispose() {
    _cameraController?.dispose(); // Muy importante liberar la cámara al salir
    super.dispose();
  }

  // --- LÓGICA PRINCIPAL ---
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      // Usamos la cámara frontal por defecto
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () =>
            cameras.first, // Si no hay frontal, usa la primera que encuentre
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Error al inicializar la cámara: $e");
      setState(() {
        _errorMessage =
            "No se pudo acceder a la cámara. Asegúrate de tener los permisos.";
        _currentStep = RegistrationStep.completed; // Va a la pantalla de error
      });
    }
  }

  Future<void> _takePicture() async {
    if (!_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return;
    }
    if (_capturedImages.length >= _captureGoal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tienes todas las fotos necesarias.')),
      );
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImages.add(image);
      });

      if (_capturedImages.length == 7) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¡Excelente Progreso!'),
            content: const Text(
              'Ya tienes varias fotos de frente. Para las siguientes, intenta variar un poco para mejorar la precisión:\n\n'
              '• Gira tu cabeza ligeramente a la izquierda y derecha.\n'
              '• Aléjate o acércate un poco a la cámara.\n'
              '• Intenta con diferentes expresiones faciales.',
            ),
            actions: [
              TextButton(
                child: const Text('Entendido'),
                onPressed: () {
                  // Cierra la ventana de diálogo
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Error al tomar la foto: $e");
    }
  }

  // --- CÓDIGO CORREGIDO Y FINAL ---
  Future<void> _uploadImages() async {
    // 1. Cambiamos al estado de "subiendo" para mostrar la rueda de carga
    setState(() {
      _currentStep = RegistrationStep.uploading;
    });

    try {
      // 2. Llamamos al método que creamos en nuestro ApiService
      final String personName = _nameController.text.trim();
      await _apiService.uploadRegistrationImages(_capturedImages, personName);

      // 3. Si la llamada fue exitosa (no lanzó excepción), pasamos al estado "completado" con un mensaje de éxito.
      if (!mounted) return;
      setState(() {
        _completionMessage =
            '¡Tu rostro ha sido registrado con éxito! Será procesado en breve.';
        _currentStep = RegistrationStep.completed;
      });
    } catch (e) {
      // 4. Si hubo un error (de red, de token, del servidor), lo capturamos
      if (!mounted) return;
      setState(() {
        // Guardamos el mensaje de error para mostrarlo en la pantalla de completado
        _completionMessage = 'Error al registrar tu rostro:\n${e.toString()}';
        _currentStep = RegistrationStep.completed;
      });
    }
  }

  // --- CONSTRUCCIÓN DE LA INTERFAZ ---
  // --- CÓDIGO CORREGIDO Y FINAL ---
  // Reemplaza el método build completo con este:
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro Facial')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // LayoutBuilder nos da el tamaño del área disponible (constraints).
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Forzamos al contenido a tener al menos el alto de la pantalla.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                // IntrinsicHeight asegura que la Column se dibuje correctamente.
                child: Center(child: _buildUIForStep(_currentStep)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUIForStep(RegistrationStep step) {
    switch (step) {
      case RegistrationStep.instructions:
        return _buildInstructionsUI();
      case RegistrationStep.nameInput: // <-- AÑADE ESTE CASE
        return _buildNameInputUI();
      case RegistrationStep.capturing:
        return _buildCapturingUI();
      case RegistrationStep.uploading:
        return _buildUploadingUI();
      case RegistrationStep.completed:
        return _buildCompletedUI();
    }
  }

  // --- WIDGETS PARA CADA ETAPA ---
  Widget _buildInstructionsUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.info_outline, size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            'Prepara tu Registro Facial',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text(
            'A continuación, tomarás $_captureGoal fotos de tu rostro. Sigue estos consejos:',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 15),
          const ListTile(
            leading: Icon(Icons.lightbulb_outline),
            title: Text('Asegúrate de tener buena iluminación.'),
          ),
          const ListTile(
            leading: Icon(Icons.face_retouching_natural),
            title: Text('Mira directamente a la cámara.'),
          ),
          const ListTile(
            leading: Icon(Icons.rotate_90_degrees_ccw),
            title: Text(
              'Gira ligeramente tu cabeza para las siguientes fotos.',
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              // Ahora va al paso de introducir el nombre
              setState(() {
                _currentStep = RegistrationStep.nameInput;
              });
            },
            child: const Text('¡Entendido, empezar!'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInputUI() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.badge_outlined, size: 60, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              '¿Quién es esta persona?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              'Escribe el nombre que aparecerá en las notificaciones y el historial (ej: "Papá", "Ana", "Técnico de servicio").',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Persona',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, introduce un nombre.';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Validamos que el campo no esté vacío
                if (_formKey.currentState!.validate()) {
                  // Si es válido, pasamos a la captura
                  setState(() {
                    _currentStep = RegistrationStep.capturing;
                  });
                  _initializeCamera();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
              ),
              child: const Text('Continuar a la Captura'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturingUI() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const CircularProgressIndicator();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        // Esta columna organiza todo el contenido de la pantalla de captura
        children: [
          // 1. EL CUADRO DE LA CÁMARA
          // Usamos AspectRatio para darle un tamaño fijo y proporcional
          AspectRatio(
            aspectRatio:
                4.5 /
                8.0, // Proporción (ancho/alto). 3/4 es un buen tamaño vertical.
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CameraPreview(_cameraController!),
            ),
          ),

          const SizedBox(
            height: 24,
          ), // Un espacio entre la cámara y el progreso
          // 2. EL CONTADOR Y LA BARRA DE PROGRESO
          Text(
            '${_capturedImages.length} / $_captureGoal fotos capturadas',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _capturedImages.length / _captureGoal,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: Colors.grey[300],
          ),

          const Spacer(), // Este widget empuja los botones hacia el final de la pantalla
          // 3. LA FILA DE BOTONES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Botón para borrar la última foto
              IconButton(
                iconSize: 36,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Borrar última foto',
                onPressed: _capturedImages.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _capturedImages.removeLast();
                        });
                      },
              ),

              // Botón principal de captura
              FloatingActionButton(
                onPressed: _takePicture,
                tooltip: 'Tomar Foto',
                child: const Icon(Icons.camera_alt, size: 40),
                shape: const CircleBorder(),
                elevation: 4.0,
              ),

              // Botón para subir
              IconButton(
                iconSize: 36,
                tooltip: 'Subir y Registrar',
                icon: Icon(
                  Icons.cloud_upload_outlined,
                  color: _capturedImages.length < _captureGoal
                      ? Colors.grey
                      : Colors.green,
                ),
                onPressed: _capturedImages.length < _captureGoal
                    ? null
                    : _uploadImages,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingUI() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Procesando tu rostro...', style: TextStyle(fontSize: 18)),
        Text('Esto puede tardar un momento.'),
      ],
    );
  }

  Widget _buildCompletedUI() {
    final bool success = _errorMessage.isEmpty;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: success ? Colors.green : Colors.red,
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            success ? _completionMessage : _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver al Dashboard'),
          ),
        ],
      ),
    );
  }
}
