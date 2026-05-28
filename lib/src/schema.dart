enum ColumnType { integer, text, real, blob }

class Col {
  final String name;
  final ColumnType type;
  final bool isPrimaryKey;
  final bool isAutoIncrement;
  final bool isRequired;
  final String? defaultValue;

  const Col({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    this.isAutoIncrement = false,
    this.isRequired = false,
    this.defaultValue,
  });

  String get definition {
    final buf = StringBuffer(name);
    buf.write(' ${type.name.toUpperCase()}');
    if (isPrimaryKey) buf.write(' PRIMARY KEY');
    if (isAutoIncrement) buf.write(' AUTOINCREMENT');
    if (isRequired) buf.write(' NOT NULL');
    if (defaultValue != null) buf.write(' DEFAULT $defaultValue');
    return buf.toString();
  }
}

Col integer(String name) => Col(name: name, type: ColumnType.integer);
Col text(String name) => Col(name: name, type: ColumnType.text);
Col real(String name) => Col(name: name, type: ColumnType.real);
Col blob(String name) => Col(name: name, type: ColumnType.blob);

extension ColMod on Col {
  Col primaryKey() => Col(
    name: name, type: type, isPrimaryKey: true,
    isAutoIncrement: isAutoIncrement, isRequired: isRequired,
    defaultValue: defaultValue,
  );

  Col autoIncrement() => Col(
    name: name, type: type, isPrimaryKey: isPrimaryKey,
    isAutoIncrement: true, isRequired: isRequired,
    defaultValue: defaultValue,
  );

  Col required() => Col(
    name: name, type: type, isPrimaryKey: isPrimaryKey,
    isAutoIncrement: isAutoIncrement, isRequired: true,
    defaultValue: defaultValue,
  );

  Col defaultTo(String value) => Col(
    name: name, type: type, isPrimaryKey: isPrimaryKey,
    isAutoIncrement: isAutoIncrement, isRequired: isRequired,
    defaultValue: value,
  );
}

class Table {
  final String name;
  final List<Col> columns;

  const Table(this.name, this.columns);

  String get createSql {
    final defs = columns.map((c) => c.definition).join(', ');
    return 'CREATE TABLE "$name" ($defs)';
  }

  String get pkName {
    try {
      return columns.firstWhere((c) => c.isPrimaryKey).name;
    } catch (_) {
      return 'id';
    }
  }
}
