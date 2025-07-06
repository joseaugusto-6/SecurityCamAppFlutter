import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart'; // ¡Importa PhotoView!

class EventImageViewerScreen extends StatelessWidget {
  final String imageUrl; // La URL de la imagen a mostrar

  const EventImageViewerScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Imagen del Evento'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        // El fondo negro es común para visores de imágenes
        color: Colors.black,
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl), // Carga la imagen desde la URL
          minScale: PhotoViewComputedScale.contained * 0.8, // Escala mínima
          maxScale: PhotoViewComputedScale.covered * 2, // Escala máxima
          heroAttributes: PhotoViewHeroAttributes(
            tag: imageUrl,
          ), // Para una transición suave
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) {
            // Indicador de carga mientras la imagen se descarga
            return Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded /
                          (event.expectedTotalBytes ??
                              event.cumulativeBytesLoaded),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            // Mensaje de error si la imagen no carga
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Error al cargar la imagen.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
