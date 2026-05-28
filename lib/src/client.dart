import 'package:flutter/widgets.dart';

import '../pulse_db.dart';

mixin PulseDbMixin<T extends StatefulWidget> on State<T> {
  late final PulseDb _db;
  final _completer = _DbCompleter();

  PulseDb get db => _db;
  bool get dbReady => _completer.ready;

  void initDb(
    String path, {
    List<Migration> migrations = const [],
    void Function(PulseDb db)? onReady,
  }) {
    _db = PulseDb();
    _db.open(path, migrations: migrations);
    _completer.complete();
    onReady?.call(_db);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }
}

class _DbCompleter {
  bool _ready = false;
  bool get ready => _ready;
  void complete() => _ready = true;
}
