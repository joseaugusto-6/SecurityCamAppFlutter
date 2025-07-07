import 'package:flutter/material.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/screens/dashboard_screen.dart';
import 'package:my_first_app/screens/event_history_screen.dart'; // <-- ¡ESTA LÍNEA ES CLAVE!
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:my_first_app/services/auth_service.dart';

// Función global para manejar mensajes en segundo plano o terminados
// Se ejecuta cuando la app no está en primer plano y recibe una notificación.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('DEBUG: Handling a background message: ${message.messageId}');
  // Aquí puedes añadir lógica para procesar el mensaje en segundo plano,
  // como guardar en una base de datos local o disparar una notificación
}

// GlobalKey para acceder al contexto del Navigator y ScaffoldMessenger desde cualquier parte.
// Es necesaria para mostrar SnackBar o diálogos desde funciones fuera de un Widget.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de cualquier operación asíncrona.
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones específicas de la plataforma.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configurar el handler para mensajes en segundo plano.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- CONFIGURACIÓN Y MANEJO INICIAL DE FCM ---
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Solicitar permisos de notificación (para iOS y Android 13+).
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('DEBUG: User granted permission for notifications');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('DEBUG: User granted provisional permission');
  } else {
    print('DEBUG: User declined or has not accepted permission');
  }

  // Manejar mensajes en primer plano (cuando la app está abierta y activa).
  // Estos mensajes no aparecen automáticamente en la bandeja de notificaciones;
  // deben ser manejados por el código de la app.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('DEBUG: Got a message whilst in the foreground!');
    print('DEBUG: Message data: ${message.data}');

    if (message.notification != null) {
      print(
        'DEBUG: Message also contained a notification: ${message.notification!.title} / ${message.notification!.body}',
      );
      // Aquí mostramos la SnackBar para notificaciones en primer plano.
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text(
              message.notification!.body ?? 'Nueva notificación',
            ), // Muestra el cuerpo de la notificación
            action: SnackBarAction(
              label: 'Ver', // Botón en la SnackBar
              onPressed: () {
                // --- INICIO DE LA LÓGICA DE NAVEGACIÓN ---
                // Oculta la SnackBar antes de navegar para evitar conflictos visuales
                ScaffoldMessenger.of(
                  navigatorKey.currentContext!,
                ).hideCurrentSnackBar();

                // Navega a la EventHistoryScreen
                navigatorKey.currentState!.push(
                  MaterialPageRoute(
                    builder: (context) => const EventHistoryScreen(),
                  ),
                );
                // --- FIN DE LA LÓGICA DE NAVEGACIÓN ---

                print(
                  'DEBUG: SnackBar Action Pressed and navigating to history',
                );
              },
            ),
            duration: const Duration(seconds: 5), // Duración de la SnackBar
            backgroundColor: Colors.blueAccent, // Color de fondo de la SnackBar
            behavior:
                SnackBarBehavior.floating, // Para que flote sobre el contenido
          ),
        );
      }
    }
  });

  // Manejar interacciones con notificaciones cuando la app está en segundo plano o terminada.
  // Esto se activa si el usuario toca una notificación en la bandeja.
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('DEBUG: A New onMessageOpenedApp event was published!');
    print('DEBUG: Message data: ${message.data}');
    // TODO: Aquí puedes añadir lógica para navegar a una pantalla específica basada en los datos de la notificación.
    // Por ejemplo, si message.data contiene un 'event_id', puedes ir a la pantalla de detalles de ese evento.
  });

  // Si la app se abre desde una notificación que estaba en la bandeja (cuando la app estaba terminada).
  // Esto es para manejar el caso cuando la app no estaba corriendo y se lanza por una notificación.
  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    print('DEBUG: App opened from terminated state via a notification!');
    print('DEBUG: Initial Message data: ${initialMessage.data}');
    // TODO: Similar a onMessageOpenedApp, aquí puedes navegar a una pantalla específica.
  }
  // --- FIN CONFIGURACIÓN Y MANEJO INICIAL DE FCM ---

  // Lógica para determinar la pantalla inicial (auto-login o LoginScreen).
  final AuthService authService = AuthService();
  String? jwtToken;
  try {
    jwtToken = await authService.getJwtToken();
  } catch (e) {
    print('DEBUG: Error getting JWT token during app startup: $e');
    jwtToken = null;
  }

  Widget initialScreen;
  if (jwtToken != null) {
    print(
      'DEBUG: Found existing JWT. Attempting to send FCM token and auto-login.',
    );
    bool fcmTokenSent = await authService.sendFcmTokenToBackend(
      "auto_login_placeholder",
    );

    if (fcmTokenSent) {
      initialScreen = const DashboardScreen();
    } else {
      print(
        'DEBUG: FCM token sending failed, likely due to expired JWT. Redirecting to Login.',
      );
      initialScreen = const LoginScreen();
    }
  } else {
    print('DEBUG: No JWT found. Redirecting to Login Screen.');
    initialScreen = const LoginScreen();
  }

  // Ejecuta el widget que manejará la lógica de carga y redirección inicial.
  runApp(MyApp(initialScreen: initialScreen));
}

// Nuevo widget para manejar la carga inicial y la redirección.
// Muestra un CircularProgressIndicator mientras se determina la pantalla inicial.
class InitialAppLoader extends StatefulWidget {
  const InitialAppLoader({super.key});

  @override
  State<InitialAppLoader> createState() => _InitialAppLoaderState();
}

class _InitialAppLoaderState extends State<InitialAppLoader> {
  late Widget _initialScreen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp(); // Llama a la función asíncrona para inicializar la aplicación.
  }

  Future<void> _initializeApp() async {
    final AuthService authService = AuthService();
    String? jwtToken;
    try {
      jwtToken = await authService.getJwtToken();
    } catch (e) {
      print('DEBUG: Error getting JWT token during app startup: $e');
      jwtToken = null;
    }

    if (jwtToken != null) {
      print(
        'DEBUG: Found existing JWT. Attempting to send FCM token and auto-login.',
      );
      await authService.sendFcmTokenToBackend("auto_login_placeholder");
      _initialScreen = const DashboardScreen();
    } else {
      print('DEBUG: No JWT found. Redirecting to Login Screen.');
      _initialScreen = const LoginScreen();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    } else {
      return MyApp(initialScreen: _initialScreen);
    }
  }
}

// El widget principal de tu aplicación.
class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Security Cam App',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: navigatorKey, // Asigna la GlobalKey al MaterialApp aquí.
      home: initialScreen, // Usa la pantalla inicial que se le pasó.
    );
  }
}
