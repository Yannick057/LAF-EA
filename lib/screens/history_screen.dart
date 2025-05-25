import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/grouping.dart';
import 'export_screen.dart';
import 'edit_entry_screen.dart';
import 'dart:io';

// Format JJ/MM/AAAA
String formatDateFr(String dateIso) {
  try {
    final parts = dateIso.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } else {
      return dateIso;
    }
  } catch (_) {
    return dateIso;
  }
}

Color getFraudColor(double taux) {
  if (taux < 5) return Colors.green;
  if (taux < 8) return Colors.orange;
  return Colors.red;
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Set<int> selectedIndexes = {};

  void clearSelection() {
    setState(() {
      selectedIndexes.clear();
    });
  }

  String formatEntry(Map entry) {
    final buffer = StringBuffer();
    buffer.writeln('Heure de départ : ${entry['departureTime']}');
    if (entry['controlledPeople'] != null && entry['controlledPeople'] > 0) {
      buffer.writeln('Personnes contrôlées : ${entry['controlledPeople']}');
      int pvCount = (entry['pvs'] as List?)?.length ?? 0;
      int controleCount = (entry['controles'] as List?)?.length ?? 0;
      double taux = entry['controlledPeople'] == 0 ? 0 : ((pvCount + controleCount) / entry['controlledPeople']) * 100;
      buffer.writeln('Taux de fraude : ${taux.toStringAsFixed(1)}%');
    }
    final List tickets = entry['tickets'] ?? [];
    if (tickets.isNotEmpty) {
      buffer.writeln('Billets : ${tickets.length}');
      for (var t in tickets) {
        buffer.writeln('- ${t['type']}: ${t['amount']} €');
      }
    }
    final List controles = entry['controles'] ?? [];
    if (controles.isNotEmpty) {
      buffer.writeln('Billets contrôle : ${controles.length}');
      for (var c in controles) {
        buffer.writeln('- ${c['type']}: ${c['amount']} €');
      }
    }
    final List pvs = entry['pvs'] ?? [];
    if (pvs.isNotEmpty) {
      buffer.writeln('PV : ${pvs.length}');
      for (var pv in pvs) {
        buffer.writeln('- ${pv['type']}: ${pv['amount']} €');
      }
    }
    if ((entry['riPositif'] ?? false) || (entry['riNegatif'] ?? false)) {
      buffer.write('RI : ');
      if (entry['riPositif'] ?? false) buffer.write('Positif ');
      if (entry['riNegatif'] ?? false) buffer.write('Négatif ');
      buffer.writeln();
    }
    if ((entry['comment'] ?? '').toString().trim().isNotEmpty) {
      buffer.writeln('Commentaire : ${entry['comment']}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('laf_data');
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, _, __) {
        final items = box.values.toList().cast<Map>();
        if (items.isEmpty) {
          return const Center(child: Text('Aucune saisie enregistrée.'));
        }
        final grouped = groupByDay(items);

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                for (final day in grouped.keys)
                  ...[
                    Container(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey[700] : Colors.blue[50],
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        formatDateFr(day),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.yellow : Colors.blue[900],
                        ),
                      ),
                    ),
                    ...grouped[day]!.map((entry) {
                      final idx = items.indexOf(entry);

                      // Calcul du taux de fraude
                      final int pvCount = (entry['pvs'] as List?)?.length ?? 0;
                      final int controleCount = (entry['controles'] as List?)?.length ?? 0;
                      final int nbControlled = entry['controlledPeople'] ?? 0;
                      final double tauxFraude = nbControlled == 0 ? 0 : ((pvCount + controleCount) / nbControlled) * 100;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: selectedIndexes.contains(idx) ? Colors.blue[50] : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            leading: (entry['photoPath'] != null && entry['photoPath'].toString().isNotEmpty)
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: getFraudColor(tauxFraude), size: 15),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Container(
                                          color: Colors.black,
                                          padding: const EdgeInsets.all(8),
                                          child: Image.file(
                                            File(entry['photoPath']),
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(entry['photoPath']),
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: getFraudColor(tauxFraude), size: 15),
                                const SizedBox(width: 4),
                                const Icon(Icons.train, color: Colors.deepPurple, size: 40),
                              ],
                            ),
                            title: Text(
                              'Train ${entry['trainNumber']} - ${entry['origin']} > ${entry['destination']}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              (entry['timestamp']?.toString().substring(11, 16) ?? '') +
                                  (entry['controlledPeople'] != null ? ' — ${entry['controlledPeople']} contrôlés' : ''),
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditEntryScreen(index: idx, data: entry),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Confirmer la suppression'),
                                        content: const Text('Voulez-vous vraiment supprimer cette saisie ?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Annuler'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Supprimer'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm ?? false) {
                                      await box.deleteAt(idx);
                                      setState(() {
                                        selectedIndexes.remove(idx);
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    selectedIndexes.contains(idx)
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (selectedIndexes.contains(idx)) {
                                        selectedIndexes.remove(idx);
                                      } else {
                                        selectedIndexes.add(idx);
                                      }
                                    });
                                  },
                                  tooltip: selectedIndexes.isEmpty
                                      ? "Exporter (sélection multiple)"
                                      : "Sélectionner/désélectionner",
                                ),
                              ],
                            ),
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Détails de la saisie'),
                                content: SingleChildScrollView(
                                  child: Text(formatEntry(entry)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fermer'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ]
              ],
            ),
            // Bouton d'export en bas si sélection active
            if (selectedIndexes.isNotEmpty)
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: Text("Exporter la sélection (${selectedIndexes.length})"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.green[600],
                  ),
                  onPressed: () {
                    final toExport = selectedIndexes.map((i) => items[i]).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExportHistoryScreen(items: toExport),
                      ),
                    );
                    clearSelection();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
