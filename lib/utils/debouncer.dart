// lib/utils/debouncer.dart
import 'dart:async';
import 'package:flutter/foundation.dart'; // Pour VoidCallback

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Annule le timer précédent et en démarre un nouveau.
  /// L'action ne sera exécutée qu'après la fin du délai.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Important : à appeler dans la méthode dispose() de votre State
  void dispose() {
    _timer?.cancel();
  }
}
