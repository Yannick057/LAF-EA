import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  // Initialisation obligatoire pour toute opération asynchrone avant runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Hive et ouvrir les box pour la sauvegarde locale
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await Hive.openBox('laf_data');     // Pour stocker les saisies de formulaires
  await Hive.openBox('settings');     // Pour stocker le thème choisi, etc.

  // Lire le mode thème choisi ou par défaut (0 = light)
  final themeIndex = Hive.box('settings').get('themeMode', defaultValue: 0);

  // Lancer l'application
  runApp(
    LAFRoot(initialThemeMode: ThemeMode.values[themeIndex]),
  );
}

// Widget racine qui gère le thème (clair/sombre)
class LAFRoot extends StatefulWidget {
  final ThemeMode initialThemeMode;
  const LAFRoot({super.key, required this.initialThemeMode});
  @override
  State<LAFRoot> createState() => _LAFRootState();
}

class _LAFRootState extends State<LAFRoot> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      Hive.box('settings').put('themeMode', _themeMode.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAF',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomeScreen(
        onToggleTheme: _toggleTheme,
        themeMode: _themeMode,
      ),
    );
  }
}
