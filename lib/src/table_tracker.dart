final _tablePattern = RegExp(
  r'''(?:FROM|JOIN|INTO|UPDATE|TABLE)\s+["'`]?(\w+)["'`]?''',
  caseSensitive: false,
);

final _deleteFromPattern = RegExp(
  r'''DELETE\s+FROM\s+["'`]?(\w+)["'`]?''',
  caseSensitive: false,
);

Set<String> extractTables(String sql) {
  final tables = <String>{};
  for (final match in _tablePattern.allMatches(sql)) {
    tables.add(match.group(1)!.toLowerCase());
  }
  for (final match in _deleteFromPattern.allMatches(sql)) {
    tables.add(match.group(1)!.toLowerCase());
  }
  return tables;
}
