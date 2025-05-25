import 'package:flutter/material.dart';
import '../utils/backup_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Sauvegarder/Partager la base'),
            subtitle: const Text('Exporter la base Hive (.hive)'),
            onTap: () => backupHiveDatabase(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Restaurer la base'),
            subtitle: const Text('Importer une sauvegarde .hive'),
            onTap: () => restoreHiveDatabase(context),
          ),
          const Divider(),
          // Ajoute d'autres réglages ici si besoin
        ],
      ),
    );
  }
}
