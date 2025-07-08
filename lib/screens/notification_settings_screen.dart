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

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final bool isSelected = value == _currentPreference;
    final Color selectedColor = Theme.of(context).primaryColor;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? selectedColor : Colors.grey.shade300,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _handlePreferenceChange(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : Colors.grey.shade600,
                size: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _currentPreference,
                onChanged: (val) => _handlePreferenceChange(val!),
                activeColor: selectedColor,
              ),
            ],
          ),
        ),
      ),
    );
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Cuándo te gustaría recibir notificaciones?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Tarjeta para la opción "Todos los eventos"
                  _buildOptionCard(
                    title: 'Todos los eventos',
                    subtitle: 'Recibirás una alerta por cualquier persona.',
                    icon: Icons.notifications,
                    value: 'all',
                  ),

                  const SizedBox(height: 12),

                  // Tarjeta para la opción "Solo Alertas"
                  _buildOptionCard(
                    title: 'Solo Alertas Críticas',
                    subtitle: 'Solo por desconocidos o alarmas.',
                    icon: Icons.warning_amber_rounded,
                    value: 'alerts_only',
                  ),
                ],
              ),
            ),
    );
  }
}
