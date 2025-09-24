import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'home.dart';
import 'catalogo.dart';
import 'solicitudes.dart';
import 'profile.dart';
import 'notification.dart';
import 'gestiondepedidos.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String catalogo = '/catalogo';
  static const String solicitudes = '/solicitudes';
  static const String profile = '/profile';
  static const String notification = '/notification';
  static const String gestiondepedidos = '/gestiondepedidos';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case catalogo:
        return MaterialPageRoute(builder: (_) => const CatalogoScreen());
      case solicitudes:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const PerfilPage());
      case notification:
        return MaterialPageRoute(builder: (_) => NotificacionesScreen());
      case gestiondepedidos:
        return MaterialPageRoute(builder: (_) => const GestionDePedidos());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No existe la ruta: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
