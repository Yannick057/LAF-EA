import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';

const List<String> villesFrequentes = [
  'Metz', 'Nancy', 'Thionville', 'Hagondange', 'Bettembourg', 'Epinal', 'Luxembourg',
  'St Die', 'Strasbourg', 'Pont à Mousson', 'Luneville', 'Conflans Jarny',
  'Verdun', 'Bar-le-Duc',
];

class LAFForm extends StatefulWidget {
  const LAFForm({super.key});
  @override
  State<LAFForm> createState() => _LAFFormState();
}

class _LAFFormState extends State<LAFForm> {
  final _formKey = GlobalKey<FormState>();

  final trainNumberController = TextEditingController();
  final originController = TextEditingController();
  final destinationController = TextEditingController();
  final departureTimeController = TextEditingController();
  final commentController = TextEditingController();
  int controlledPeople = 0;
  final controlledPeopleController = TextEditingController(text: '0');

  bool riPositif = false;
  bool riNegatif = false;

  List<Map<String, TextEditingController>> ticketControllers = [];
  List<Map<String, TextEditingController>> controleControllers = [];
  List<Map<String, TextEditingController>> pvControllers = [];

  final List<String> ticketTypes = ['Bord', 'Exceptionnel'];
  final List<String> controleTypes = ['STT', 'RNV', 'Titre tiers', 'D naissance', 'Autre'];
  final List<String> pvTypes = ['STT', 'RNV', 'Titre tiers', 'D naissance', 'Autre'];

  String? photoPath;

  @override
  void initState() {
    super.initState();
    _addTicket();
    _addControle();
    _addPV();
  }

  void _addTicket() {
    setState(() {
      ticketControllers.add({
        'type': TextEditingController(text: ticketTypes[0]),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeTicket(int index) {
    setState(() {
      ticketControllers.removeAt(index);
    });
  }

  void _addControle() {
    setState(() {
      controleControllers.add({
        'type': TextEditingController(text: controleTypes[0]),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeControle(int index) {
    setState(() {
      controleControllers.removeAt(index);
    });
  }

  void _addPV() {
    setState(() {
      pvControllers.add({
        'type': TextEditingController(text: pvTypes[0]),
        'amount': TextEditingController(),
      });
    });
  }

  void _removePV(int index) {
    setState(() {
      pvControllers.removeAt(index);
    });
  }

  double _computeTauxFraude() {
    final pvCount = pvControllers.where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty).length;
    final controleCount = controleControllers.where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty).length;
    if (controlledPeople == 0) return 0.0;
    return ((pvCount + controleCount) / controlledPeople) * 100;
  }

  void _updateTauxFraudeAuto() {
    setState(() {});
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        photoPath = picked.path;
      });
    }
  }

  Future<void> _saveData() async {
    final box = Hive.box('laf_data');
    final tickets = ticketControllers
        .where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty)
        .map((ctrl) => {
      'type': ctrl['type']!.text,
      'amount': ctrl['amount']!.text,
    }).toList();
    final controles = controleControllers
        .where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty)
        .map((ctrl) => {
      'type': ctrl['type']!.text,
      'amount': ctrl['amount']!.text,
    }).toList();
    final pvs = pvControllers
        .where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty)
        .map((ctrl) => {
      'type': ctrl['type']!.text,
      'amount': ctrl['amount']!.text,
    }).toList();

    final data = {
      'trainNumber': trainNumberController.text,
      'origin': originController.text,
      'destination': destinationController.text,
      'departureTime': departureTimeController.text,
      'tickets': tickets,
      'controles': controles,
      'pvs': pvs,
      'controlledPeople': controlledPeople,
      'riPositif': riPositif,
      'riNegatif': riNegatif,
      'comment': commentController.text,
      'timestamp': DateTime.now().toIso8601String(),
      'photoPath': photoPath,
    };
    await box.add(data);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données enregistrées localement')),
    );
    trainNumberController.clear();
    originController.clear();
    destinationController.clear();
    departureTimeController.clear();
    commentController.clear();
    controlledPeopleController.text = '0';
    controlledPeople = 0;
    riPositif = false;
    riNegatif = false;
    ticketControllers.clear();
    controleControllers.clear();
    pvControllers.clear();
    photoPath = null;
    _addTicket();
    _addControle();
    _addPV();
    setState(() {});
  }

  void _incrementPeople() {
    setState(() {
      controlledPeople++;
      controlledPeopleController.text = controlledPeople.toString();
    });
  }

  void _decrementPeople() {
    setState(() {
      if (controlledPeople > 0) {
        controlledPeople--;
        controlledPeopleController.text = controlledPeople.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardMargin = const EdgeInsets.symmetric(horizontal: 10, vertical: 9);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(6),
        children: [
          // --- Informations générales ---
          Card(
            elevation: 6,
            color: Colors.blue[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informations générales', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.blue)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: trainNumberController,
                    decoration: const InputDecoration(labelText: 'Numéro de train'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _updateTauxFraudeAuto(),
                    maxLines: 1,
                  ),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') return const Iterable<String>.empty();
                      return villesFrequentes.where((String option) =>
                          option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      controller.text = originController.text;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Origine'),
                        onChanged: (value) {
                          originController.text = value;
                          _updateTauxFraudeAuto();
                        },
                        maxLines: 1,
                      );
                    },
                    onSelected: (String selection) {
                      originController.text = selection;
                    },
                  ),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') return const Iterable<String>.empty();
                      return villesFrequentes.where((String option) =>
                          option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      controller.text = destinationController.text;
                      controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.text.length),
                      );
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(labelText: 'Destination'),
                        onChanged: (value) {
                          destinationController.text = value;
                          _updateTauxFraudeAuto();
                        },
                        maxLines: 1,
                      );
                    },
                    onSelected: (String selection) {
                      destinationController.text = selection;
                    },
                  ),
                  TextFormField(
                    controller: departureTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Heure de départ',
                      hintText: '08:30',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    maxLines: 1,
                    onChanged: (value) {
                      if (value.length == 2 && !value.contains(':')) {
                        departureTimeController.text = '$value:';
                        departureTimeController.selection = TextSelection.fromPosition(
                          TextPosition(offset: departureTimeController.text.length),
                        );
                      }
                      _updateTauxFraudeAuto();
                    },
                    validator: (value) {
                      final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
                      if (value == null || !regex.hasMatch(value)) {
                        return 'Format invalide (HH:mm)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          // --- PERSONNES CONTRÔLÉES ---
          Card(
            elevation: 6,
            color: Colors.teal[50], // Vert d’eau très doux
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personnes contrôlées',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _decrementPeople,
                        color: Colors.teal,
                      ),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          controller: controlledPeopleController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              controlledPeople = int.tryParse(value) ?? 0;
                            });
                          },
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _incrementPeople,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  if (controlledPeople > 0 || controlledPeopleController.text == '0')
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                      child: Text(
                        'Taux de fraude : ${_computeTauxFraude().toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal, // Taux de fraude en teal
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- Billets contrôle ---
          Card(
            elevation: 5,
            color: Colors.deepPurple[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billets contrôle (${controleControllers.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepPurple),
                  ),
                  for (int i = 0; i < controleControllers.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: controleControllers[i]['type']!.text == 'Autre'
                              ? TextFormField(
                            controller: controleControllers[i]['type'],
                            decoration: const InputDecoration(labelText: 'Type (Autre)'),
                            onChanged: (_) => _updateTauxFraudeAuto(),
                            maxLines: 1,
                          )
                              : DropdownButtonFormField(
                            value: controleControllers[i]['type']!.text,
                            decoration: const InputDecoration(labelText: 'Type contrôle'),
                            items: controleTypes
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              setState(() => controleControllers[i]['type']!.text = val!);
                              _updateTauxFraudeAuto();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: controleControllers[i]['amount'],
                            decoration: const InputDecoration(labelText: 'Montant'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _updateTauxFraudeAuto(),
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeControle(i),
                        )
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addControle,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un contrôle'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- PV ---
          Card(
            elevation: 5,
            color: Colors.red[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PV (${pvControllers.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                  ),
                  for (int i = 0; i < pvControllers.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: pvControllers[i]['type']!.text == 'Autre'
                              ? TextFormField(
                            controller: pvControllers[i]['type'],
                            decoration: const InputDecoration(labelText: 'Type (Autre)'),
                            onChanged: (_) => _updateTauxFraudeAuto(),
                            maxLines: 1,
                          )
                              : DropdownButtonFormField(
                            value: pvControllers[i]['type']!.text,
                            decoration: const InputDecoration(labelText: 'Type PV'),
                            items: pvTypes
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              setState(() => pvControllers[i]['type']!.text = val!);
                              _updateTauxFraudeAuto();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: pvControllers[i]['amount'],
                            decoration: const InputDecoration(labelText: 'Montant'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _updateTauxFraudeAuto(),
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removePV(i),
                        )
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addPV,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un PV'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- Billets exceptionnels / bord ---
          Card(
            elevation: 5,
            color: Colors.green[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billets exceptionnels / bord (${ticketControllers.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green),
                  ),
                  for (int i = 0; i < ticketControllers.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField(
                            value: ticketControllers[i]['type']!.text,
                            decoration: const InputDecoration(labelText: 'Type'),
                            items: ticketTypes
                                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                .toList(),
                            onChanged: (val) {
                              setState(() => ticketControllers[i]['type']!.text = val!);
                              _updateTauxFraudeAuto();
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: ticketControllers[i]['amount'],
                            decoration: const InputDecoration(labelText: 'Montant'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _updateTauxFraudeAuto(),
                            maxLines: 1,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _removeTicket(i),
                        )
                      ],
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addTicket,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un billet'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // --- RI ---
          Card(
            elevation: 2,
            color: Colors.blue[50], // Bleu très clair
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              child: Row(
                children: [
                  const Text(
                    'RI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue, // Titre bleu foncé
                      fontSize: 16,
                    ),
                  ),
                  Checkbox(
                    value: riPositif,
                    onChanged: (v) => setState(() => riPositif = v ?? false),
                    activeColor: Colors.blue,
                  ),
                  const Text('positif'),
                  Checkbox(
                    value: riNegatif,
                    onChanged: (v) => setState(() => riNegatif = v ?? false),
                    activeColor: Colors.blue,
                  ),
                  const Text('négatif'),
                ],
              ),
            ),
          ),
          // --- Commentaire ---
          Card(
            elevation: 2,
            color: Colors.grey[100], // Gris très clair, neutre
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TextFormField(
                controller: commentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Commentaire',
                  labelStyle: TextStyle(color: Colors.blue), // Label bleu foncé
                ),
              ),
            ),
          ),
          // --- Photo associée ---
          Card(
            elevation: 2,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: cardMargin,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photo associée', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: Icon(Icons.camera_alt),
                        label: Text('Prendre une photo'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: Icon(Icons.photo),
                        label: Text('Galerie'),
                      ),
                      if (photoPath != null && photoPath!.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => photoPath = null),
                          tooltip: 'Supprimer la photo',
                        ),
                    ],
                  ),
                  if (photoPath != null && photoPath!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Container(
                                color: Colors.black,
                                padding: const EdgeInsets.all(8),
                                child: Image.file(
                                  File(photoPath!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Image.file(
                          File(photoPath!),
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _saveData();
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                elevation: 6,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
