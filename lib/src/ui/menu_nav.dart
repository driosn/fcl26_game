import 'package:flutter/foundation.dart';

/// Which pause / game-over button is selected, shared by the pad and the panel.
///
/// The game drains `menuPrev` / `menuNext` / `confirm` into this; [MenuPanel]
/// paints the highlight and registers the callbacks.
class MenuNavController {
  final ValueNotifier<int> index = ValueNotifier(0);

  List<VoidCallback> _actions = const [];
  bool _disposed = false;

  bool get hasActions => _actions.isNotEmpty;

  int get count => _actions.length;

  void bind(List<VoidCallback> actions, {int initial = 0}) {
    _actions = List<VoidCallback>.of(actions);
    if (_actions.isEmpty) {
      index.value = 0;
      return;
    }
    index.value = initial.clamp(0, _actions.length - 1);
  }

  void unbind() {
    _actions = const [];
  }

  void next() {
    if (_actions.isEmpty) {
      return;
    }
    index.value = (index.value + 1) % _actions.length;
  }

  void prev() {
    if (_actions.isEmpty) {
      return;
    }
    index.value = (index.value - 1 + _actions.length) % _actions.length;
  }

  void select(int value) {
    if (_actions.isEmpty) {
      return;
    }
    index.value = value.clamp(0, _actions.length - 1);
  }

  void activate() {
    if (_actions.isEmpty) {
      return;
    }
    _actions[index.value]();
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    index.dispose();
  }
}
