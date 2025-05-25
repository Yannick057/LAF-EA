import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

Future<void> backupHiveDatabase(BuildContext context) async {
  final dir = await getApplicationDocumentsDirectory();
  final hiveFile = File('${dir.path}/laf_data.hive');
  if (!await hiveFile.exists()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune base à sauvegarder !')),
    );
    return;
  }
  final tempDir = await getTemporaryDirectory();
  final backupFile = await hiveFile.copy('${tempDir.path}/laf_data_backup.hive');
  await Share.shareXFiles(
    [XFile(backupFile.path)],
    text: "Sauvegarde LAF EA",
  );
}

Future<void> restoreHiveDatabase(BuildContext context) async {
  print("Bouton restaurer appuyé"); // Debug

  final result = await FilePicker.platform.pickFiles(
    type: FileType.any, // Compatible partout, plus de bug de filtre
  );
  print("Résultat FilePicker: $result");

  if (result != null && result.files.single.path != null) {
    print("Fichier sélectionné: ${result.files.single.path!}");
    final pickedFile = File(result.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();
    final hiveFile = File('${dir.path}/laf_data.hive');
    await pickedFile.copy(hiveFile.path);
    print("Copie effectuée vers ${hiveFile.path}");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Base restaurée ! Veuillez relancer l\'application.')),
    );
  } else {
    print("Aucun fichier sélectionné !");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun fichier sélectionné')),
    );
  }
}
