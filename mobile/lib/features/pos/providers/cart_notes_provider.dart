import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartNotesNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? val) => super.state = val;
}

final cartNotesProvider = NotifierProvider<CartNotesNotifier, String?>(
  CartNotesNotifier.new,
);
