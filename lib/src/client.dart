import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../pulse_db.dart';

mixin PulseDbMixin<T extends StatefulWidget> on State<T> {
  late final PulseDb _db;
  final _subs = <StreamSubscription>[];
  bool _dbReady = false;

  PulseDb get db => _db;
  bool get dbReady => _dbReady;

  Future<void> initDb({
    String? path,
    String databaseName = 'default.db',
    List<Migration>? migrations,
  }) async {
    _db = PulseDb();
    _db.open(
      path ?? '${(await getApplicationDocumentsDirectory()).path}/$databaseName',
      migrations: migrations ?? [],
    );
    _dbReady = true;
    if (mounted) setState(() {});
  }

  ValueNotifier<List<R>> observe<R>(Repository<R> repo) {
    final n = ValueNotifier<List<R>>([]);
    n.addListener(() {
      if (mounted) setState(() {});
    });
    final sub = repo.watch().listen((items) {
      n.value = items;
    });
    _subs.add(sub);
    return n;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _db.close();
    super.dispose();
  }
}
