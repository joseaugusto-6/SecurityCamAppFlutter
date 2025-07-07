// Asegúrate de que esta importación esté aquí
import 'package:flutter/foundation.dart';

class PersonEvent {
  final String personName;
  final DateTime timestamp;
  final String eventType;
  final String imageUrl;
  final String eventDetails;
  final String deviceId;

  PersonEvent({
    required this.personName,
    required this.timestamp,
    required this.eventType,
    required this.imageUrl,
    this.eventDetails = '',
    required this.deviceId,
  });

  factory PersonEvent.fromJson(Map<String, dynamic> json) {
    DateTime parsedTimestamp;
    try {
      // Intentar parsear como ISO 8601 y EXPLICITAMENTE marcarlo como UTC
      parsedTimestamp = DateTime.parse(json['timestamp']).toUtc();
    } catch (e) {
      // Fallback si el parseo falla (aunque no debería si Flask envía ISO)
      // Intenta parsear sin asumir UTC y luego convertir (menos ideal)
      parsedTimestamp = DateTime.parse(json['timestamp']);
      debugPrint(
        'Error al parsear timestamp como UTC. Intentando sin toUtc(): ${json['timestamp']} - Error: $e',
      );
    }

    return PersonEvent(
      personName: json['person_name'] as String? ?? 'Desconocido',
      timestamp: parsedTimestamp,
      eventType: json['event_type'] as String? ?? 'unknown',
      imageUrl: json['image_url'] as String? ?? '',
      eventDetails: json['event_details'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person_name': personName,
      'timestamp': timestamp
          .toIso8601String(), // Asegurar que siempre se envíe como ISO 8601
      'event_type': eventType,
      'image_url': imageUrl,
      'event_details': eventDetails,
      'device_id': deviceId,
    };
  }
}
