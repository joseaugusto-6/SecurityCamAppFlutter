import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:my_first_app/services/auth_service.dart';

// URL base de tu API de Flask en la VM de GCP
const String BASE_URL =
    'https://tesisdeteccion.ddns.net/api'; // ¡Asegúrate que esta URL sea correcta!

class ApiService {
  final FlutterSecureStorage _secureStorage;
  final AuthService _authService;

  ApiService({FlutterSecureStorage? secureStorage, AuthService? authService})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
      _authService = authService ?? AuthService();

  // Método para obtener los datos del dashboard (últimos eventos y estadísticas)
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/dashboard_data'),
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
      print('DEBUG_API: Error fetching dashboard data: $e');
      rethrow;
    }
  }

  // Método: Obtener la lista de dispositivos del usuario
  Future<List<String>> getUserDevices() async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.get(
        Uri.parse('$BASE_URL/user_devices'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return List<String>.from(responseData['devices'] ?? []);
      } else if (response.statusCode == 401) {
        await _authService.deleteJwtToken();
        throw Exception('Authentication failed. Please login again.');
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['msg'] ?? 'Failed to load user devices.');
      }
    } catch (e) {
      print('DEBUG_API: Error fetching user devices: $e');
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
        Uri.parse('$BASE_URL/add_device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'device_id': deviceId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('DEBUG_API: Dispositivo añadido: ${responseData['msg']}');
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
      print('DEBUG_API: Error adding device: $e');
      rethrow;
    }
  }

  // NUEVO MÉTODO: Eliminar un dispositivo para el usuario actual
  Future<void> removeDevice(String deviceId) async {
    try {
      final String? token = await _authService.getJwtToken();

      if (token == null) {
        throw Exception('No JWT token found. User not authenticated.');
      }

      final response = await http.post(
        // Usamos POST como en el backend
        Uri.parse(
          '$BASE_URL/remove_device',
        ), // Tu endpoint para eliminar dispositivo
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'device_id': deviceId,
        }), // Enviar el ID del dispositivo
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('DEBUG_API: Dispositivo eliminado: ${responseData['msg']}');
      } else if (response.statusCode == 404) {
        // 404 Not Found si el dispositivo no está asociado
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
      print('DEBUG_API: Error removing device: $e');
      rethrow;
    }
  }
}
