// lib/services/auth_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String BASE_URL = 'https://tesisdeteccion.ddns.net/api';

class AuthService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> saveJwtToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
  }

  // Modificado para limpiar el token si hay un error de lectura
  Future<String?> getJwtToken() async {
    try {
      return await _secureStorage.read(key: 'jwt_token');
    } catch (e) {
      print('DEBUG: Error reading JWT token from secure storage: $e');
      await deleteJwtToken(); // Eliminar token si hay error de lectura
      return null;
    }
  }

  Future<void> deleteJwtToken() async {
    await _secureStorage.delete(key: 'jwt_token');
  }

  // Modificado para manejar token expirado
  Future<bool> sendFcmTokenToBackend(String userEmailPlaceholder) async {
    try {
      final String? fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null) {
        print('DEBUG: No FCM token available to send.');
        return false;
      }

      final String? jwtToken = await getJwtToken();
      if (jwtToken == null) {
        print(
          'DEBUG: No JWT token available. Cannot send FCM token. User might not be logged in.',
        );
        return false;
      }

      final response = await http.post(
        Uri.parse('$BASE_URL/fcm_token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode({'fcm_token': fcmToken}),
      );

      if (response.statusCode == 200) {
        print(
          'DEBUG: FCM Token sent successfully to backend for user via JWT.',
        );
        return true;
      } else if (response.statusCode == 401) {
        // <-- ¡Manejo del 401 aquí!
        print(
          'DEBUG: Token expired or invalid. Deleting token and requiring re-login.',
        );
        await deleteJwtToken(); // Eliminar el token expirado/inválido
        return false; // Indicar que falló porque el token está expirado
      } else {
        print(
          'DEBUG: Failed to send FCM Token to backend. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      print('DEBUG: Error sending FCM token to backend: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$BASE_URL/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final String accessToken = responseData['access_token'];
        await saveJwtToken(accessToken);
        return {'success': true, 'token': accessToken, 'user_email': email};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'msg': errorData['msg'] ?? 'Error de inicio de sesión.',
        };
      }
    } catch (e) {
      return {'success': false, 'msg': 'Error de conexión: $e'};
    }
  }
}
