Map<String, List<Map>> groupByDay(List<Map> entries) {
  final Map<String, List<Map>> grouped = {};
  for (final entry in entries) {
    final dateStr = entry['timestamp']?.toString().split('T').first ?? '???';
    grouped.putIfAbsent(dateStr, () => []).add(entry);
  }
  final sorted = Map.fromEntries(grouped.entries.toList()
    ..sort((a, b) => b.key.compareTo(a.key)));
  return sorted;
}
