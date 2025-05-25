/// Fonction utilitaire pour regrouper des entrées (saisies)
/// par jour, selon leur champ 'timestamp'.
Map<String, List<Map>> groupByDay(List<Map> entries) {
  final Map<String, List<Map>> grouped = {};
  for (final entry in entries) {
    // Extrait la date (YYYY-MM-DD) de l'horodatage ISO
    final dateStr = entry['timestamp']?.toString().split('T').first ?? '???';
    grouped.putIfAbsent(dateStr, () => []).add(entry);
  }
  // Trie les jours du plus récent au plus ancien
  final sorted = Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key))
  );
  return sorted;
}
