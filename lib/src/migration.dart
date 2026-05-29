import 'schema.dart';

class Migration {
  final int version;
  final String up;
  final String? down;

  const Migration({
    required this.version,
    required this.up,
    this.down,
  });

  factory Migration.table(int version, TableDef table) =>
    Migration(version: version, up: table.createSql);
}
