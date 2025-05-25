import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher et gérer dynamiquement une liste de tickets/contrôles/PV.
/// Chaque ligne propose un dropdown (ou champ texte si "Autre") et un montant.
/// Utilisation : voir le README ou tes écrans de formulaire/édition.
class TicketFields extends StatelessWidget {
  final String label; // Le titre affiché pour la section
  final List<String> typeList; // Liste des types proposés (Dropdown)
  final List<Map<String, TextEditingController>> controllers;
  final void Function() onAdd;
  final void Function(int) onRemove;
  final void Function() onChanged;

  const TicketFields({
    super.key,
    required this.label,
    required this.typeList,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        for (int i = 0; i < controllers.length; i++)
          Row(
            children: [
              // Type (Dropdown ou champ texte si "Autre")
              Expanded(
                child: controllers[i]['type']!.text == 'Autre'
                    ? TextFormField(
                        controller: controllers[i]['type'],
                        decoration: const InputDecoration(labelText: 'Type (Autre)'),
                        onChanged: (_) => onChanged(),
                      )
                    : DropdownButtonFormField<String>(
                        value: controllers[i]['type']!.text,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: typeList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          controllers[i]['type']!.text = val!;
                          onChanged();
                        },
                      ),
              ),
              const SizedBox(width: 10),
              // Montant
              Expanded(
                child: TextFormField(
                  controller: controllers[i]['amount'],
                  decoration: const InputDecoration(labelText: 'Montant'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
              // Supprimer ce champ (si plus d'un champ)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => onRemove(i),
              )
            ],
          ),
        // Bouton ajouter
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
