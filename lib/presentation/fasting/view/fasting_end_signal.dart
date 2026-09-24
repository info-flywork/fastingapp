import 'package:flutter/foundation.dart';

/// Orucu erken bitirme isteği. Oruç sekmesi dinler.
final class FastingEndSignal {
  FastingEndSignal._();

  static final notifier = ValueNotifier<int>(0);

  static void request() => notifier.value++;
}
