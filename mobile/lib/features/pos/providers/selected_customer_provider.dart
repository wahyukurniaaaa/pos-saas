import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';

class SelectedCustomerNotifier extends Notifier<Customer?> {
  @override
  Customer? build() => null;

  set state(Customer? val) => super.state = val;
}

final selectedCustomerProvider = NotifierProvider<SelectedCustomerNotifier, Customer?>(
  SelectedCustomerNotifier.new,
);

class ManualCustomerNameNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? val) => super.state = val;
}

final manualCustomerNameProvider = NotifierProvider<ManualCustomerNameNotifier, String?>(
  ManualCustomerNameNotifier.new,
);

class ManualCustomerPhoneNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  set state(String? val) => super.state = val;
}

final manualCustomerPhoneProvider = NotifierProvider<ManualCustomerPhoneNotifier, String?>(
  ManualCustomerPhoneNotifier.new,
);
