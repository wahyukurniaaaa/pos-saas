import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumio/core/services/receipt_service.dart';

final receiptServiceProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});
