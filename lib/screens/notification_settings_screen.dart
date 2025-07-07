// Archivo: lib/screens/notification_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:my_first_app/services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();
  String _currentPreference = 'all'; // Valor por defecto mientras carga
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _apiService.getUserSettings();
      if (mounted) {
        setState(() {
          _currentPreference = settings['notification_preference'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ajustes: ${e.toString()}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePreferenceChange(String? value) async {
    if (value == null) return;

    final originalPreference = _currentPreference;

    // Actualización optimista de la UI
    setState(() {
      _currentPreference = value;
    });

    try {
      await _apiService.updateUserSettings(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferencia guardada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        // Si falla, revertimos el cambio en la UI
        setState(() {
          _currentPreference = originalPreference;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes de Notificaciones'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(8.0),
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: Text(
                    '¿Cuándo te gustaría recibir notificaciones push?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                RadioListTile<String>(
                  title: const Text('Todos los eventos'),
                  subtitle: const Text(
                    'Recibirás una alerta por cualquier persona detectada (conocida o desconocida).',
                  ),
                  value: 'all',
                  groupValue: _currentPreference,
                  onChanged: _handlePreferenceChange,
                ),
                RadioListTile<String>(
                  title: const Text('Solo Alertas Críticas'),
                  subtitle: const Text(
                    'Solo recibirás alertas por personas desconocidas o eventos de alarma.',
                  ),
                  value: 'alerts_only',
                  groupValue: _currentPreference,
                  onChanged: _handlePreferenceChange,
                ),
              ],
            ),
    );
  }
}
