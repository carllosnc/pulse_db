import 'package:flutter/foundation.dart';

import '../pulse_db.dart';

class ObservableList<R> extends ValueNotifier<List<R>> {
  final Repository<R>? Function() _repoAccessor;
  bool _loaded = false;

  ObservableList(this._repoAccessor) : super([]);

  bool get isLoading => !_loaded;
  bool get isEmpty => _loaded && value.isEmpty;
  Repository<R>? get repo => _repoAccessor();

  @override
  set value(List<R> v) {
    _loaded = true;
    super.value = v;
  }
}
