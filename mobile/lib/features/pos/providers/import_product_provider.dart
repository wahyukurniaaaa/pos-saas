import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart' as csv_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'pos_providers.dart';

class ImportProductState {
  final bool isLoading;
  final String? error;
  final int importedCount;

  ImportProductState({
    this.isLoading = false,
    this.error,
    this.importedCount = 0,
  });

  ImportProductState copyWith({
    bool? isLoading,
    String? error,
    int? importedCount,
  }) {
    return ImportProductState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      importedCount: importedCount ?? this.importedCount,
    );
  }
}

class ImportProductNotifier extends Notifier<ImportProductState> {
  @override
  ImportProductState build() {
    return ImportProductState();
  }

  Future<void> importCsv() async {
    // AVOID USING state GETTER IF IT MIGHT NOT BE INITIALIZED
    // Use a fresh object for the first update
    state = ImportProductState(isLoading: true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        state = ImportProductState(isLoading: false);
        return;
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final content = utf8.decode(bytes);

      final fields = const csv_pkg.CsvDecoder().convert(content);

      if (fields.isEmpty) {
        throw Exception('File CSV kosong');
      }

      final db = ref.read(databaseProvider);
      final List<ProductsCompanion> companions = [];

      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 3) continue;

        final name = row[0].toString().trim();
        if (name.isEmpty) continue;

        final sku = (row.length > 1 && row[1].toString().trim().isNotEmpty)
            ? row[1].toString().trim()
            : 'SKU-${DateTime.now().millisecondsSinceEpoch}-$i';

        final pricePrice =
            int.tryParse(row[2].toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
        final stockStock =
            int.tryParse(row.length > 3 ? row[3].toString() : '0') ?? 0;
        final categoryId =
            (row.length > 4 && row[4].toString().trim().isNotEmpty) ? row[4].toString().trim() : 'uuid-dimpor';
        final imageUri = (row.length > 5 && row[5].toString().trim().isNotEmpty)
            ? row[5].toString().trim()
            : null;

        companions.add(
          ProductsCompanion.insert(
            name: name,
            sku: sku,
            price: pricePrice,
            stock: Value(stockStock),
            categoryId: categoryId,
            imageUri: Value(imageUri),
          ),
        );
      }

      if (companions.isNotEmpty) {
        await db.insertMultipleProducts(companions);
        ref.invalidate(productProvider);
      }

      state = ImportProductState(
        isLoading: false,
        importedCount: companions.length,
      );
    } catch (e) {
      state = ImportProductState(
        isLoading: false,
        error: 'Gagal mengimpor: ${e.toString()}',
      );
    }
  }
}

final importProductProvider =
    NotifierProvider<ImportProductNotifier, ImportProductState>(
      ImportProductNotifier.new,
    );
