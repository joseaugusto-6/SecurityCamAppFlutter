import 'package:flutter/material.dart';
import 'package:my_first_app/models/person_event.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha y hora

class EventCard extends StatelessWidget {
  final PersonEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Formatear la fecha y hora para una mejor lectura
    final String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
    ).format(event.timestamp);

    // Lógica para determinar el título, subtítulo e icono basado en el tipo de evento
    String titleText;
    String subtitleText;
    IconData iconData;
    Color iconColor;

    switch (event.eventType) {
      case 'known_person':
        titleText = 'Persona Conocida Detectada';
        subtitleText = 'Nombre: ${event.personName}';
        iconData = Icons.person_outline;
        iconColor = Colors.green;
        break;
      case 'unknown_person':
        titleText = 'Alerta: Persona Desconocida';
        subtitleText =
            'Detalles: ${event.eventDetails.isNotEmpty ? event.eventDetails : 'Se detectó una persona no identificada.'}';
        iconData = Icons.warning_amber;
        iconColor = Colors.red;
        break;
      case 'alarm': // Si tienes un tipo de evento 'alarm' para otras situaciones
        titleText = '¡Alarma Activada!';
        subtitleText =
            'Detalles: ${event.eventDetails.isNotEmpty ? event.eventDetails : 'Alarma de seguridad.'}';
        iconData = Icons.notifications_active;
        iconColor = Colors.orange;
        break;
      default: // Tipo de evento por defecto o desconocido
        titleText = 'Evento Desconocido';
        subtitleText =
            'Tipo: ${event.eventType} - Detalles: ${event.eventDetails}';
        iconData = Icons.info_outline;
        iconColor = Colors.grey;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: iconColor, size: 30.0),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Text(subtitleText, style: const TextStyle(fontSize: 16.0)),
            if (event.imageUrl.isNotEmpty) // Mostrar imagen si hay URL
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Center(
                  child: Image.network(
                    event.imageUrl,
                    height: 150, // Altura fija para las imágenes
                    fit: BoxFit.cover,
                    loadingBuilder:
                        (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8.0),
            Text(
              'Dispositivo: ${event.deviceId}',
              style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
