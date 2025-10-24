import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Assure-toi que Flutter est bien initialisé avant d'exécuter du code async
  WidgetsFlutterBinding.ensureInitialized();

  // Charger le fichier .env (à la racine du projet)
  await dotenv.load(fileName: ".env");

  // Lancer l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // optionnel
      home: Scaffold(
        appBar: AppBar(title: const Text('Test App')),
        body: const Center(
          child: Text(
            'Ça fonctionne enfin!',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
