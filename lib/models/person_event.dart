import 'package:cloud_firestore/cloud_firestore.dart';

class PersonEvent {
  final String personName;
  final DateTime timestamp;
  final String eventType; // 'known_person', 'unknown_person', 'alarm'
  final String imageUrl;
  final String eventDetails; // Detalles adicionales del evento
  final String deviceId; // ID del dispositivo que generó el evento

  PersonEvent({
    required this.personName,
    required this.timestamp,
    required this.eventType,
    required this.imageUrl,
    this.eventDetails = '', // Valor por defecto vacío
    required this.deviceId,
  });

  factory PersonEvent.fromJson(Map<String, dynamic> json) {
    // Manejar el timestamp que puede venir como String (de la API) o Timestamp (de Firestore)
    DateTime parsedTimestamp;
    if (json['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(json['timestamp']);
    } else if (json['timestamp'] is Timestamp) {
      parsedTimestamp = (json['timestamp'] as Timestamp).toDate();
    } else {
      // Fallback o error si el tipo no es el esperado
      parsedTimestamp = DateTime.now(); // O manejar el error de otra forma
    }

    return PersonEvent(
      personName: json['person_name'] as String? ?? 'Desconocido',
      timestamp: parsedTimestamp,
      eventType:
          json['event_type'] as String? ??
          'unknown', // Asegura que este campo exista
      imageUrl: json['image_url'] as String? ?? '',
      eventDetails:
          json['event_details'] as String? ??
          '', // Asegura que este campo exista
      deviceId: json['device_id'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person_name': personName,
      'timestamp': timestamp.toIso8601String(),
      'event_type': eventType,
      'image_url': imageUrl,
      'event_details': eventDetails,
      'device_id': deviceId,
    };
  }
}
