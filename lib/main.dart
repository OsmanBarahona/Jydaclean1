import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'src/screens/routes.dart';
import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/services/products_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    Permission.notification.request()
  ]);
  runApp(const JydacleanApp());
}

class JydacleanApp extends StatelessWidget {
  const JydacleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        ChangeNotifierProvider(create: (context) => ProductsService()),
      ],
      child: MaterialApp(
        title: 'Jydaclean',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF009CA8),
          useMaterial3: true,
        ),
        initialRoute: Routes.login,
        onGenerateRoute: Routes.generateRoute,
      ),
    );
  }
}
