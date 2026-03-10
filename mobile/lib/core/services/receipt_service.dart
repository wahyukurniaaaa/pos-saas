import 'dart:io';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';

class ReceiptService {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<void> printReceipt({
    required StoreProfileData? profile,
    required Transaction transaction,
    required List<TransactionItemWithProduct> items,
  }) async {
    final bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      throw Exception('Printer tidak terhubung');
    }

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd/MM/yy HH:mm');

    // 1. Header (Logo & Store Info)
    if (profile?.logoUri != null && profile!.logoUri!.isNotEmpty) {
      if (await File(profile.logoUri!).exists()) {
        await bluetooth.printImage(profile.logoUri!);
      }
    }

    await bluetooth.printCustom(profile?.name ?? 'POSIFY STORE', 2, 1);

    if (profile?.address != null) {
      await bluetooth.printCustom(profile!.address!, 0, 1);
    }
    if (profile?.phone != null) {
      await bluetooth.printCustom('Telp: ${profile!.phone!}', 0, 1);
    }

    await bluetooth.printCustom('--------------------------------', 0, 1);

    // 2. Transaction Info
    await bluetooth.printCustom('No: ${transaction.receiptNumber}', 0, 0);
    await bluetooth.printCustom(
      'Tgl: ${dateFmt.format(transaction.createdAt)}',
      0,
      0,
    );
    await bluetooth.printCustom('--------------------------------', 0, 1);

    // 3. Items
    for (final item in items) {
      await bluetooth.printCustom(item.product.name, 0, 0);

      final String qtyPrice =
          '${item.item.quantity} x ${currency.format(item.item.priceAtTransaction)}';
      final String subtotal = currency.format(item.item.subtotal);

      // Attempt manual padding for 32 columns
      final int spaceCount = 32 - qtyPrice.length - subtotal.length;
      final String line =
          qtyPrice + (' ' * (spaceCount > 0 ? spaceCount : 1)) + subtotal;

      await bluetooth.printCustom(line, 0, 0);
    }

    await bluetooth.printCustom('--------------------------------', 0, 1);

    // 4. Summary
    await _printRow(currency, 'Subtotal', transaction.subtotal);
    if (transaction.taxAmount > 0) {
      await _printRow(currency, 'Pajak', transaction.taxAmount);
    }
    if (transaction.serviceChargeAmount > 0) {
      await _printRow(
        currency,
        'Service Charge',
        transaction.serviceChargeAmount,
      );
    }

    await bluetooth.printCustom('--------------------------------', 0, 1);

    // Total (Bold/Large)
    final String totalLabel = 'TOTAL';
    final String totalValue = currency.format(transaction.totalAmount);
    final int totalSpace =
        20 - totalLabel.length - totalValue.length; // 20 for size 1
    final String totalLine =
        totalLabel + (' ' * (totalSpace > 0 ? totalSpace : 1)) + totalValue;
    await bluetooth.printCustom(totalLine, 1, 0);

    await bluetooth.printCustom('--------------------------------', 0, 1);
    await bluetooth.printCustom(
      'Metode Bayar: ${transaction.paymentMethod.toUpperCase()}',
      0,
      1,
    );

    await bluetooth.printNewLine();
    await bluetooth.printCustom('Terima Kasih', 1, 1);
    await bluetooth.printCustom('Sudah Berbelanja', 0, 1);

    await bluetooth.printNewLine();
    await bluetooth.printNewLine();
    await bluetooth.printNewLine();
    await bluetooth.paperCut();
  }

  Future<void> _printRow(
    NumberFormat currency,
    String label,
    int amount,
  ) async {
    final String val = currency.format(amount);
    final int spaceCount = 32 - label.length - val.length;
    final String line = label + (' ' * (spaceCount > 0 ? spaceCount : 1)) + val;
    await bluetooth.printCustom(line, 0, 0);
  }
}
