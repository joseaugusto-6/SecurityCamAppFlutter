import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/services/auth_service.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:camera/camera.dart';

// URL base de tu API de Flask en la VM de GCP
class ApiService {
  static const String BASE_URL = 'https://tesisdeteccion.ddns.net/api';

  final FlutterSecureStorage _secureStorage;
  final AuthService _authService;

  // Constructor de ApiService. Se recomienda pasar las dependencias.
  ApiService({FlutterSecureStorage? secureStorage, AuthService? authService})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      _authService = authService ?? AuthService();

  // Pega este método dentro de la clase ApiService
  Future<Map<String, dynamic>> getProfileSummary() async {
    try {
      final String? token = await _authService.getJwtToken();
      if (token == null) throw Exception('User not authenticated.');

      final response = await http.get(
        Uri.parse('${ApiService.BASE_URL}/user/profile_summary'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile summary.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error fetching profile summary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserSettings() async {
    try {
      final String? token = await _authService.getJwtToken();
      if (token == null) throw Exception('User not authenticated.');

      final response = await http.get(
        Uri.parse('${ApiService.BASE_URL}/user/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user settings.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error fetching user settings: $e');
      rethrow;
    }
  }

  Future<void> updateUserSettings(String preference) async {
    try {
      final String? token = await _authService.getJwtToken();
      if (token == null) throw Exception('User not authenticated.');

      final response = await http.post(
        Uri.parse('${ApiService.BASE_URL}/user/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notification_preference': preference}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to save user settings.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error updating user settings: $e');
      rethrow;
    }
  }

  // Método para obtener los datos del dashboard (últimos eventos y estadísticas)
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.BASE_URL}/dashboard_data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        List<PersonEvent> latestEvents = (responseData['latest_events'] as List)
            .map((eventJson) => PersonEvent.fromJson(eventJson))
            .toList();

        return {
          'latest_events': latestEvents,
          'total_entries_today': responseData['total_entries_today'],
          'alarms_today': responseData['alarms_today'],
        };
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to load dashboard data.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error fetching dashboard data: $e');
      rethrow;
    }
  }

  // Método: Obtener la lista de dispositivos del usuario
  Future<List<Map<String, dynamic>>> getUserDevices() async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.BASE_URL}/user_devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['devices'] ?? []);
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to load user devices.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error fetching user devices: $e');
      rethrow;
    }
  }

  // Método: Añadir un dispositivo para el usuario actual
  Future<void> addDevice(String deviceId) async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.post(
        Uri.parse('${ApiService.BASE_URL}/add_device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint('DEBUG_API: Dispositivo añadido: ${responseData['msg']}');
      } else if (response.statusCode == 409) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'El dispositivo ya está asociado.');
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to add device.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error adding device: $e');
      rethrow;
    }
  }

  // Método: Eliminar un dispositivo para el usuario actual
  Future<void> removeDevice(String deviceId) async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.post(
        Uri.parse('${ApiService.BASE_URL}/remove_device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint('DEBUG_API: Dispositivo eliminado: ${responseData['msg']}');
      } else if (response.statusCode == 404) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? 'El dispositivo no está asociado a este usuario.',
        );
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to remove device.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error removing device: $e');
      rethrow;
    }
  }

  Future<PersonEvent?> getLatestAlert() async {
    try {
      final String? token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('User not authenticated.');
      }

      final response = await http.get(
        Uri.parse('${ApiService.BASE_URL}/latest_alert'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['latest_alert'] != null) {
          // Si el servidor encontró una alerta, la convertimos a un objeto PersonEvent
          return PersonEvent.fromJson(responseData['latest_alert']);
        } else {
          // Si no hay alertas, devolvemos null
          return null;
        }
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to get latest alert.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error fetching latest alert: $e');
      rethrow;
    }
  }

  // Método: Obtener un token de sesión temporal para el stream
  Future<Map<String, dynamic>> getStreamSessionToken(String cameraId) async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.post(
        Uri.parse('${ApiService.BASE_URL}/get_stream_session_token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'camera_id': cameraId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? 'Failed to get stream session token.',
        );
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error getting stream session token: $e');
      rethrow;
    }
  }

  // Método: Enviar un comando de cambio de modo a una cámara
  Future<void> setCameraMode(String cameraId, String mode) async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.post(
        Uri.parse('${ApiService.BASE_URL}/camera_control'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'camera_id': cameraId, 'mode': mode}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint(
          'DEBUG_API: Control de cámara exitoso: ${responseData['msg']}',
        );
      } else if (response.statusCode == 403) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? 'No autorizado para controlar esta cámara.',
        );
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to control camera.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error al enviar comando a la cámara: $e');
      rethrow;
    }
  }

  // NUEVO MÉTODO: Enviar un comando de encendido/apagado a una cámara
  Future<void> setCameraPower(String deviceId, String powerState) async {
    // powerState es "ON" o "OFF"
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.post(
        Uri.parse(
          '${ApiService.BASE_URL}/camera_power',
        ), // Endpoint de control de encendido
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'camera_id': deviceId,
          'power_state': powerState,
        }), // Enviar ID y estado
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        debugPrint(
          'DEBUG_API: Control de encendido/apagado exitoso: ${responseData['msg']}',
        );
      } else if (response.statusCode == 403) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(
          errorData['msg'] ?? 'No autorizado para controlar esta cámara.',
        );
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to control camera power.');
      }
    } catch (e) {
      debugPrint(
        'DEBUG_API: Error al enviar comando de encendido/apagado a la cámara: $e',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> clearEventHistory() async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      // Usamos http.delete, que es el método correcto para una API REST de borrado
      final response = await http.delete(
        Uri.parse('${ApiService.BASE_URL}/events/clear_history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Devolvemos el JSON de la respuesta del servidor (que contiene el mensaje de éxito)
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to clear event history.');
      }
    } catch (e) {
      debugPrint('DEBUG_API: Error clearing event history: $e');
      rethrow;
    }
  }

  // Método para subir las imágenes de registro facial al backend
  Future<void> uploadRegistrationImages(
    List<XFile> images,
    String personName,
  ) async {
    try {
      // 1. Obtener el token de autenticación para identificarnos
      final String? token = await _authService.getJwtToken();
      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      // 2. Crear una petición "multipart".
      final uri = Uri.parse(
        '${ApiService.BASE_URL}/upload_registration_images',
      );
      final request = http.MultipartRequest('POST', uri);

      // 3. Añadir las cabeceras, incluyendo nuestro token de autorización
      request.headers['Authorization'] = 'Bearer $token';

      // 4. Añadimos el nombre como un campo de texto simple en la petición
      request.fields['person_name'] = personName;

      // 5. Adjuntar cada una de las imágenes a la petición
      for (var imageFile in images) {
        final file = await http.MultipartFile.fromPath(
          'images',
          imageFile.path,
        );
        request.files.add(file);
      }

      // 6. Enviar la petición y esperar la respuesta del servidor
      debugPrint(
        'Enviando ${images.length} imágenes para registrar a "$personName"...',
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // 7. Manejar la respuesta del servidor
      if (response.statusCode == 200) {
        debugPrint('Imágenes de registro subidas con éxito.');
        return;
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Error al subir las imágenes.');
      }
    } catch (e) {
      debugPrint('Error en la subida de imágenes de registro: $e');
      rethrow;
    }
  }
}
