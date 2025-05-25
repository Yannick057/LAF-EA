import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/ticket_fields.dart';
import 'dart:io';

class EditEntryScreen extends StatefulWidget {
  final int index;
  final Map data;

  const EditEntryScreen({super.key, required this.index, required this.data});

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController trainNumberController;
  late TextEditingController originController;
  late TextEditingController destinationController;
  late TextEditingController departureTimeController;
  late TextEditingController commentController;
  late TextEditingController controlledPeopleController;
  int controlledPeople = 0;
  bool riPositif = false;
  bool riNegatif = false;

  List<Map<String, TextEditingController>> ticketControllers = [];
  List<Map<String, TextEditingController>> controleControllers = [];
  List<Map<String, TextEditingController>> pvControllers = [];

  String? photoPath;

  final List<String> ticketTypes = ['Exceptionnel', 'Bord'];
  final List<String> controleTypes = ['STT', 'RNV', 'Titre tiers', 'Date naissance', 'Autre'];
  final List<String> pvTypes = ['STT', 'RNV', 'Titre tiers', 'Date naissance', 'Autre'];

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    trainNumberController = TextEditingController(text: data['trainNumber']);
    originController = TextEditingController(text: data['origin']);
    destinationController = TextEditingController(text: data['destination']);
    departureTimeController = TextEditingController(text: data['departureTime']);
    commentController = TextEditingController(text: data['comment'] ?? '');
    controlledPeople = data['controlledPeople'] ?? 0;
    controlledPeopleController = TextEditingController(text: controlledPeople.toString());
    riPositif = data['riPositif'] ?? false;
    riNegatif = data['riNegatif'] ?? false;
    photoPath = data['photoPath'];

    for (var t in data['tickets'] ?? []) {
      ticketControllers.add({
        'type': TextEditingController(text: t['type']),
        'amount': TextEditingController(text: t['amount']),
      });
    }
    if (ticketControllers.isEmpty) {
      ticketControllers.add({
        'type': TextEditingController(text: ticketTypes[0]),
        'amount': TextEditingController(),
      });
    }
    for (var c in data['controles'] ?? []) {
      controleControllers.add({
        'type': TextEditingController(text: c['type']),
        'amount': TextEditingController(text: c['amount']),
      });
    }
    if (controleControllers.isEmpty) {
      controleControllers.add({
        'type': TextEditingController(text: controleTypes[0]),
        'amount': TextEditingController(),
      });
    }
    for (var pv in data['pvs'] ?? []) {
      pvControllers.add({
        'type': TextEditingController(text: pv['type']),
        'amount': TextEditingController(text: pv['amount']),
      });
    }
    if (pvControllers.isEmpty) {
      pvControllers.add({
        'type': TextEditingController(text: pvTypes[0]),
        'amount': TextEditingController(),
      });
    }
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

  Future<void> _updateData() async {
    final box = Hive.box('laf_data');
    final tickets = ticketControllers
        .where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty)
        .map((ctrl) => {
      'type': ctrl['type']!.text,
      'amount': ctrl['amount']!.text,
    })
        .toList();
    final controles = controleControllers
        .where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty)
        .map((ctrl) => {
      'type': ctrl['type']!.text,
      'amount': ctrl['amount']!.text,
    })
        .toList();
    final pvs = pvControllers
        .where((ctrl) => ctrl['amount']!.text.trim().isNotEmpty)
        .map((ctrl) => {
      'type': ctrl['type']!.text,
      'amount': ctrl['amount']!.text,
    })
        .toList();
    final updatedData = {
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
    await box.putAt(widget.index, updatedData);
    Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la saisie')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: trainNumberController,
                decoration: const InputDecoration(labelText: 'Numéro de train'),
                onChanged: (_) => _updateTauxFraudeAuto(),
              ),
              TextFormField(
                controller: originController,
                decoration: const InputDecoration(labelText: 'Origine'),
                onChanged: (_) => _updateTauxFraudeAuto(),
              ),
              TextFormField(
                controller: destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
                onChanged: (_) => _updateTauxFraudeAuto(),
              ),
              TextFormField(
                controller: departureTimeController,
                decoration: const InputDecoration(labelText: 'Heure de départ'),
                onChanged: (_) => _updateTauxFraudeAuto(),
                validator: (value) {
                  final regex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
                  if (value == null || !regex.hasMatch(value)) {
                    return 'Format invalide (HH:mm)';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  const Text('Personnes contrôlées :'),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      controller: controlledPeopleController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8)),
                      onChanged: (value) {
                        setState(() {
                          controlledPeople = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _decrementPeople,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _incrementPeople,
                  ),
                ],
              ),
              if (controlledPeople > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                    'Taux de fraude : ${_computeTauxFraude().toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                  ),
                ),
              TicketFields(
                label: 'Billets exceptionnels / bord',
                typeList: ticketTypes,
                controllers: ticketControllers,
                onAdd: _addTicket,
                onRemove: _removeTicket,
                onChanged: _updateTauxFraudeAuto,
              ),
              TicketFields(
                label: 'Billets contrôle',
                typeList: controleTypes,
                controllers: controleControllers,
                onAdd: _addControle,
                onRemove: _removeControle,
                onChanged: _updateTauxFraudeAuto,
              ),
              TicketFields(
                label: 'PV',
                typeList: pvTypes,
                controllers: pvControllers,
                onAdd: _addPV,
                onRemove: _removePV,
                onChanged: _updateTauxFraudeAuto,
              ),
              const Text('RI', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Checkbox(
                    value: riPositif,
                    onChanged: (v) => setState(() => riPositif = v ?? false),
                  ),
                  const Text('RI positif'),
                  Checkbox(
                    value: riNegatif,
                    onChanged: (v) => setState(() => riNegatif = v ?? false),
                  ),
                  const Text('RI négatif'),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: commentController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Commentaire'),
              ),
              // SECTION PHOTO (placée juste avant le bouton enregistrer)
              const SizedBox(height: 24),
              Text('Photo associée', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _updateData();
                  }
                },
                child: const Text('Mettre à jour'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
