import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:convert';

import '../utils/grouping.dart';

// Fonction pour nommer les fichiers au format JJMMAAAA
String todayFileDate() {
  final now = DateTime.now();
  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final year = now.year.toString();
  return "$day$month$year";
}

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

class ExportHistoryScreen extends StatefulWidget {
  final List<Map> items;
  const ExportHistoryScreen({super.key, required this.items});

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  late Map<String, List<Map>> grouped;
  Map<String, bool> selectedDays = {};
  Map<Map, bool> selectedTrains = {};

  @override
  void initState() {
    super.initState();
    grouped = groupByDay(widget.items);
    for (var d in grouped.keys) {
      selectedDays[d] = false;
      for (var entry in grouped[d]!) {
        selectedTrains[entry] = false;
      }
    }
  }

  bool get hasDirectSelection {
    return widget.items.length < 10 ||
        widget.items.length == getSelectedEntries().length;
  }

  List<Map> getExportList() {
    return hasDirectSelection ? widget.items : getSelectedEntries();
  }

  List<Map> getSelectedEntries() {
    final List<Map> selected = [];
    selectedDays.forEach((day, checked) {
      if (checked) {
        selected.addAll(grouped[day]!);
      }
    });
    selectedTrains.forEach((entry, checked) {
      if (checked && !selected.contains(entry)) selected.add(entry);
    });
    return selected;
  }

  // --- Export texte brut et partage
  Future<void> exportTextWith(List<Map> entries) async {
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aucune saisie sélectionnée")));
      return;
    }
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln('Train ${entry['trainNumber']} - ${entry['origin']} > ${entry['destination']}');
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
      buffer.writeln('---');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${todayFileDate()}.txt';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(file.path)], subject: "Export LAF", text: "Fichier exporté : ${todayFileDate()}.txt");
  }

  // --- Génère le texte pour l'e-mail
  Future<String> generateExportText(List<Map> entries) async {
    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer.writeln('Train ${entry['trainNumber']} - ${entry['origin']} > ${entry['destination']}');
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
      buffer.writeln('---');
    }
    return buffer.toString();
  }

  // --- Envoie le mail avec le texte dans le corps
  Future<void> sendMailWithBody(String subject, String body) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'fabrice.georges@sncf.fr',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // --- Export PDF (sommaire sans lien + détail par jour)
  Future<void> exportPDFWith(List<Map> entries) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final grouped = groupByDay(entries);

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text('Trains exportés', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, font: ttf)),
            pw.SizedBox(height: 10),
            // Sommaire simple (sans liens)
            ...grouped.keys.map((day) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${formatDateFr(day)} :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: ttf)),
                pw.Wrap(
                  spacing: 12,
                  children: [
                    for (final entry in grouped[day]!)
                      pw.Text('${entry['trainNumber']}', style: pw.TextStyle(color: PdfColors.blue800, fontWeight: pw.FontWeight.bold, font: ttf)),
                  ],
                ),
                pw.SizedBox(height: 6),
              ],
            )),
            pw.SizedBox(height: 24),
            pw.Text('Détail des trains', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800, font: ttf)),
            pw.SizedBox(height: 10),
            ...grouped.keys.expand((day) => grouped[day]!.map((entry) {
              final widgets = <pw.Widget>[
                pw.Text(
                  'Train ${entry['trainNumber']} - ${entry['origin']} > ${entry['destination']}',
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.blue900, fontWeight: pw.FontWeight.bold, font: ttf),
                ),
              ];

              // PHOTO
              if ((entry['photoPath'] ?? '').toString().isNotEmpty) {
                final File imageFile = File(entry['photoPath']);
                if (imageFile.existsSync()) {
                  final imageBytes = imageFile.readAsBytesSync();
                  final image = pw.MemoryImage(imageBytes);
                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8, top: 8),
                      child: pw.Image(image, width: 150, height: 120, fit: pw.BoxFit.cover),
                    ),
                  );
                }
              }

              widgets.add(
                pw.Text('Heure de départ : ${entry['departureTime']}', style: pw.TextStyle(font: ttf)),
              );

              final List tickets = entry['tickets'] ?? [];
              final List controles = entry['controles'] ?? [];
              final List pvs = entry['pvs'] ?? [];
              int pvCount = pvs.length;
              int controleCount = controles.length;
              int controlled = entry['controlledPeople'] ?? 0;
              double taux = controlled == 0 ? 0 : ((pvCount + controleCount) / controlled) * 100;

              if (controlled > 0) {
                widgets.add(pw.Text('Personnes contrôlées : $controlled', style: pw.TextStyle(font: ttf)));
                widgets.add(pw.Text('Taux de fraude : ${taux.toStringAsFixed(1)}%', style: pw.TextStyle(color: PdfColors.red, font: ttf)));
              }
              if (tickets.isNotEmpty) {
                widgets.add(pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text('Billets : ${tickets.length}', style: pw.TextStyle(color: PdfColors.green800, font: ttf)),
                ));
                widgets.addAll(tickets.map((t) => pw.Text('- ${t['type']}: ${t['amount']} €', style: pw.TextStyle(font: ttf))));
              }
              if (controles.isNotEmpty) {
                widgets.add(pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text('Billets contrôle : ${controles.length}', style: pw.TextStyle(color: PdfColors.orange700, font: ttf)),
                ));
                widgets.addAll(controles.map((c) => pw.Text('- ${c['type']}: ${c['amount']} €', style: pw.TextStyle(font: ttf))));
              }
              if (pvs.isNotEmpty) {
                widgets.add(pw.Container(
                  margin: const pw.EdgeInsets.only(top: 5),
                  child: pw.Text('PV : ${pvs.length}', style: pw.TextStyle(color: PdfColors.red800, font: ttf)),
                ));
                widgets.addAll(pvs.map((pv) => pw.Text('- ${pv['type']}: ${pv['amount']} €', style: pw.TextStyle(font: ttf))));
              }
              if ((entry['riPositif'] ?? false) || (entry['riNegatif'] ?? false)) {
                widgets.add(pw.Text(
                  'RI : ${(entry['riPositif'] ?? false) ? "Positif " : ""}${(entry['riNegatif'] ?? false) ? "Négatif " : ""}',
                  style: pw.TextStyle(color: PdfColors.purple700, font: ttf),
                ));
              }
              if ((entry['comment'] ?? '').toString().trim().isNotEmpty) {
                widgets.add(pw.Text('Commentaire : ${entry['comment']}', style: pw.TextStyle(font: ttf)));
              }

              widgets.add(pw.SizedBox(height: 14));

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                padding: const pw.EdgeInsets.all(10),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: widgets,
                ),
              );
            })),
          ];
        },
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: "${todayFileDate()}.pdf");
  }

  // --- Génère et sauvegarde HTML avec sommaire, liens, photo ---
  Future<String> generateAndSaveHtml(List<Map> entries) async {
    final grouped = groupByDay(entries);

    final buffer = StringBuffer();
    buffer.writeln('''<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Historique LAF</title>
  <style>
    body { font-family: Arial,sans-serif; background:#f6f9fc; color:#222; }
    .bloc { background: #e3eaff; border-radius: 10px; margin: 12px 0; padding: 16px; }
    .titre { color: #21408e; font-weight: bold; font-size: 18px; }
    .billets { color: #007c41; font-weight:bold; }
    .controles { color: #ff8800; font-weight:bold; }
    .pv { color: #cc0000; font-weight:bold; }
    .taux { color:#b20000; font-weight: bold; }
    .ri { color: #910088; }
    .date { color: #005ac7; }
    .comment { font-style:italic; }
    .sommaire { background: #e6f7ff; padding: 12px; border-radius: 7px; margin-bottom: 22px;}
    .sommaire h3 { color:#1c2c5b; margin-bottom:6px; }
    .jour { margin-bottom:7px; font-size: 15px; }
    .trainlink { margin-right:12px; text-decoration:none; color:#21408e; font-weight:bold; }
    .trainlink:hover { text-decoration:underline; color:#c80000; }
  </style>
</head>
<body>
<h2 style="color:#21408e">Historique LAF</h2>
''');

    // Sommaire HTML cliquable
    buffer.writeln('<div class="sommaire"><h3>Sommaire des trains exportés</h3>');
    for (final day in grouped.keys) {
      buffer.write('<div class="jour"><b>${formatDateFr(day)}</b> : ');
      for (final entry in grouped[day]!) {
        final trainNum = entry['trainNumber'];
        buffer.write('<a class="trainlink" href="#train$trainNum$day">$trainNum</a>');
      }
      buffer.writeln('</div>');
    }
    buffer.writeln('</div>');

    // Détail des trains HTML
    for (final day in grouped.keys) {
      for (final entry in grouped[day]!) {
        buffer.writeln('<div class="bloc" id="train${entry['trainNumber']}$day">');
        buffer.writeln('<div class="titre">Train ${entry['trainNumber']} - ${entry['origin']} > ${entry['destination']}</div>');

        if ((entry['photoPath'] ?? '').toString().isNotEmpty) {
          final File imageFile = File(entry['photoPath']);
          if (await imageFile.exists()) {
            final bytes = await imageFile.readAsBytes();
            final base64Img = base64Encode(bytes);
            buffer.writeln('<img src="data:image/jpeg;base64,$base64Img" width="180" style="margin-bottom:10px" alt="photo" />');
          }
        }

        buffer.writeln('<div class="date">Heure de départ : ${entry['departureTime']}</div>');

        final List tickets = entry['tickets'] ?? [];
        final List controles = entry['controles'] ?? [];
        final List pvs = entry['pvs'] ?? [];
        int pvCount = pvs.length;
        int controleCount = controles.length;
        int controlled = entry['controlledPeople'] ?? 0;
        double taux = controlled == 0 ? 0 : ((pvCount + controleCount) / controlled) * 100;
        if (controlled > 0) buffer.writeln('<div>Personnes contrôlées : $controlled</div>');
        if (controlled > 0) buffer.writeln('<div class="taux">Taux de fraude : ${taux.toStringAsFixed(1)}%</div>');
        if (tickets.isNotEmpty) {
          buffer.writeln('<div class="billets">Billets : ${tickets.length}</div>');
          for (var t in tickets) {
            buffer.writeln('<div>- ${t['type']}: ${t['amount']} €</div>');
          }
        }
        if (controles.isNotEmpty) {
          buffer.writeln('<div class="controles">Billets contrôle : ${controles.length}</div>');
          for (var c in controles) {
            buffer.writeln('<div>- ${c['type']}: ${c['amount']} €</div>');
          }
        }
        if (pvs.isNotEmpty) {
          buffer.writeln('<div class="pv">PV : ${pvs.length}</div>');
          for (var pv in pvs) {
            buffer.writeln('<div>- ${pv['type']}: ${pv['amount']} €</div>');
          }
        }
        if ((entry['riPositif'] ?? false) || (entry['riNegatif'] ?? false)) {
          buffer.write('<div class="ri">RI : ');
          if (entry['riPositif'] ?? false) buffer.write('Positif ');
          if (entry['riNegatif'] ?? false) buffer.write('Négatif ');
          buffer.writeln('</div>');
        }
        if ((entry['comment'] ?? '').toString().trim().isNotEmpty) {
          buffer.writeln('<div class="comment">Commentaire : ${entry['comment']}</div>');
        }
        buffer.writeln('</div>');
      }
    }
    buffer.writeln('</body></html>');

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/${todayFileDate()}.html';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  // --- Export HTML et partage via Share ---
  Future<void> exportHTMLWith(List<Map> entries) async {
    final path = await generateAndSaveHtml(entries);
    await Share.shareXFiles([XFile(path)], subject: "Export HTML LAF", text: "Fichier exporté : ${todayFileDate()}.html");
  }

  // --- Envoie par mail le HTML en pièce jointe ---
  Future<void> sendMailWithHtml(List<Map> entries) async {
    final path = await generateAndSaveHtml(entries);
    await Share.shareXFiles([XFile(path)],
      subject: "Export HTML LAF",
      text: "Fichier exporté : ${todayFileDate()}.html",
      sharePositionOrigin: Rect.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exportList = getExportList();
    return Scaffold(
      appBar: AppBar(title: const Text('Exporter/Mailer Historique')),
      body: hasDirectSelection
          ? ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Exporter et envoyer (texte)'),
            onPressed: () async {
              await exportTextWith(exportList);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const Text('Partager (PDF)'),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Choisissez votre application de mail dans la liste pour envoyer la pièce jointe."),
                  duration: Duration(seconds: 3),
                ),
              );
              await exportPDFWith(exportList);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.email_outlined),
            label: const Text('Partager (HTML)'),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Choisissez votre application de mail dans la liste pour envoyer la pièce jointe."),
                  duration: Duration(seconds: 3),
                ),
              );
              await sendMailWithHtml(exportList);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
          ),
        ],
      )
          : ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text("Sélectionnez les jours OU les trains à exporter :", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          // ... (ta logique de sélection si besoin) ...
        ],
      ),
    );
  }
}
