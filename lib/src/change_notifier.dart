import 'dart:async';

class ChangeNotifier {
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();
  final Set<String> _pending = {};
  Timer? _timer;
  final Duration _debounceDelay;

  ChangeNotifier({this._debounceDelay = const Duration(milliseconds: 50)});

  Stream<Set<String>> get changes => _controller.stream;

  void notify(Set<String> tables) {
    _pending.addAll(tables);
    _timer?.cancel();
    _timer = Timer(_debounceDelay, _flush);
  }

  void flush() {
    _timer?.cancel();
    _flush();
  }

  void _flush() {
    if (_pending.isNotEmpty) {
      _controller.add(Set.of(_pending));
      _pending.clear();
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
