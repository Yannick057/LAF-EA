import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'form_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart'; // <-- Ajout

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVersion();
  }

  // Charge la version de l'application (pour l'afficher dans la barre du haut)
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = info.version;
      });
    } catch (_) {
      setState(() {
        _appVersion = '';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAF EA Metz'),
        actions: [
          if (_appVersion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(child: Text('v$_appVersion', style: const TextStyle(fontSize: 16))),
            ),
          IconButton(
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
            tooltip: "Changer de thème",
          ),
          // ------- AJOUT bouton paramètres -------
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Paramètres",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          // ------- FIN AJOUT -------
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Formulaire'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: LAFForm(),
          ),
          HistoryScreen(),
        ],
      ),
    );
  }
}
