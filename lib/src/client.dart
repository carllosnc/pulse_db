import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../pulse_db.dart';

mixin PulseDbMixin<T extends StatefulWidget> on State<T> {
  PulseDb? _db;
  final _subs = <StreamSubscription>[];
  final _pending = <void Function(PulseDb)>[];
  bool _dbReady = false;
  bool _ownsDb = false;

  PulseDb get db => _db!;
  bool get dbReady => _dbReady;

  void use(PulseDb db) {
    _db = db;
    _dbReady = true;
    _flushPending();
    if (mounted) setState(() {});
  }

  Future<void> initDb({
    String? path,
    String databaseName = 'default.db',
    List<Migration>? migrations,
    List<TableDef>? tables,
  }) async {
    _ownsDb = true;
    _db = PulseDb();
    _db!.open(
      path: path ?? '${(await getApplicationDocumentsDirectory()).path}/$databaseName',
      migrations: migrations ?? [],
      tables: tables ?? [],
    );
    _dbReady = true;
    _flushPending();
    if (mounted) setState(() {});
  }

  ValueNotifier<List<R>> observe<R>(Repository<R> repo) {
    final n = ValueNotifier<List<R>>([]);
    n.addListener(_onNotifyChanged);
    final sub = repo.watch().listen((items) => n.value = items);
    _subs.add(sub);
    return n;
  }

  ValueNotifier<List<R>> autoObserve<R>(
    Repository<R> Function(PulseDb db) factory,
  ) {
    final n = ValueNotifier<List<R>>([]);
    n.addListener(_onNotifyChanged);

    void connect(PulseDb db) {
      final repo = factory(db);
      final sub = repo.watch().listen((items) => n.value = items);
      _subs.add(sub);
    }

    if (_dbReady) {
      connect(_db!);
    } else {
      _pending.add(connect);
    }
    return n;
  }

  void _flushPending() {
    for (final fn in _pending) {
      fn(_db!);
    }
    _pending.clear();
  }

  void _onNotifyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    if (_ownsDb) _db?.close();
    super.dispose();
  }
}
