import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:drift/drift.dart' as drift;

class IngredientFormScreen extends ConsumerStatefulWidget {
  final int? ingredientId;

  const IngredientFormScreen({super.key, this.ingredientId});

  @override
  ConsumerState<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends ConsumerState<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _averageCostController = TextEditingController();
  final _minStockThresholdController = TextEditingController();
  final _stockQuantityController = TextEditingController();

  String _selectedBaseUnit = 'gr'; // DB Storage Unit
  String _selectedInputUnit = 'gr'; // User Input Unit

  Ingredient? _existingIngredient;
  bool _isLoading = false;

  final Map<String, List<String>> _validInputUnits = {
    'gr': ['gr', 'kg'],
    'ml': ['ml', 'liter'],
    'pcs': ['pcs'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.ingredientId != null) {
      _loadIngredient();
    }
  }

  Future<void> _loadIngredient() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final ingredient = await db.getIngredientById(widget.ingredientId!);
    if (ingredient != null) {
      setState(() {
        _existingIngredient = ingredient;
        _nameController.text = ingredient.name;
        _selectedBaseUnit = ingredient.unit;
        _selectedInputUnit = ingredient.unit;
        _averageCostController.text = ingredient.averageCost.toStringAsFixed(0);
        _minStockThresholdController.text = ingredient.minStockThreshold.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
        _stockQuantityController.text = ingredient.stockQuantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _averageCostController.dispose();
    _minStockThresholdController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  double _convertToBaseUnit(double inputVal, String inputUnit, String baseUnit) {
    if (baseUnit == 'gr' && inputUnit.toLowerCase() == 'kg') return inputVal * 1000;
    if (baseUnit == 'ml' && inputUnit.toLowerCase() == 'liter') return inputVal * 1000;
    return inputVal;
  }

  double _convertCostToBaseUnit(double inputCost, String inputUnit, String baseUnit) {
    if (baseUnit == 'gr' && inputUnit.toLowerCase() == 'kg') return inputCost / 1000;
    if (baseUnit == 'ml' && inputUnit.toLowerCase() == 'liter') return inputCost / 1000;
    return inputCost;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final inputQty = double.tryParse(_stockQuantityController.text.replaceAll(',', '.')) ?? 0;
    final inputMinThreshold = double.tryParse(_minStockThresholdController.text.replaceAll(',', '.')) ?? 0;
    final inputCost = double.tryParse(_averageCostController.text.replaceAll(',', '.')) ?? 0;

    // Convert input constraints based on the provided unit to Base Unit
    final normalizedQty = _convertToBaseUnit(inputQty, _selectedInputUnit, _selectedBaseUnit);
    final normalizedThreshold = _convertToBaseUnit(inputMinThreshold, _selectedInputUnit, _selectedBaseUnit);
    final normalizedCost = _convertCostToBaseUnit(inputCost, _selectedInputUnit, _selectedBaseUnit);

    final db = ref.read(databaseProvider);
    final isUpdating = _existingIngredient != null;

    final companion = IngredientsCompanion(
      name: drift.Value(name),
      unit: drift.Value(_selectedBaseUnit),
      stockQuantity: drift.Value(normalizedQty),
      minStockThreshold: drift.Value(normalizedThreshold),
      averageCost: drift.Value(normalizedCost),
      updatedAt: drift.Value(DateTime.now()),
    );

    if (isUpdating) {
      await db.updateIngredient(
        _existingIngredient!.copyWith(
          name: name,
          unit: _selectedBaseUnit,
          stockQuantity: normalizedQty,
          minStockThreshold: normalizedThreshold,
          averageCost: normalizedCost,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await db.insertIngredient(companion);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingIngredient == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Informasi Dasar'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Bahan Baku',
                        hintText: 'Cth: Susu UHT, Kopi Arabica, dll',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.inventory_2_rounded),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedBaseUnit,
                      decoration: InputDecoration(
                        labelText: 'Satuan Dasar (Penyimpanan)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.straighten_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'gr', child: Text('Gram (Berat)')),
                        DropdownMenuItem(value: 'ml', child: Text('Mililiter (Volume)')),
                        DropdownMenuItem(value: 'pcs', child: Text('Pieces (Satuan)')),
                      ],
                      onChanged: _existingIngredient != null
                          ? null // Prevent changing base unit if it's already created, as it will break recipes
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedBaseUnit = value;
                                  _selectedInputUnit = _validInputUnits[value]!.first;
                                });
                              }
                            },
                    ),
                    if (_existingIngredient != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          'Catatan: Satuan dasar tidak dapat diubah setelah data tersimpan.',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    _buildSectionHeader('Nilai & Stok (Dalam $_selectedInputUnit)'),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedInputUnit,
                      decoration: InputDecoration(
                        labelText: 'Satuan Input Form Ini',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.swap_horiz_rounded),
                      ),
                      items: _validInputUnits[_selectedBaseUnit]!
                          .map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase())))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedInputUnit = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockQuantityController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            decoration: InputDecoration(
                              labelText: 'Stok Saat Ini',
                              hintText: '0',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixText: _selectedInputUnit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockThresholdController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            decoration: InputDecoration(
                              labelText: 'Minimum Stok',
                              hintText: 'Cth: 50',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixText: _selectedInputUnit,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _averageCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Harga Beli (Per $_selectedInputUnit)',
                        hintText: 'Cth: 15000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixText: 'Rp ',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final inputCost = double.tryParse(_averageCostController.text) ?? 0;
                        final baseCost = _convertCostToBaseUnit(inputCost, _selectedInputUnit, _selectedBaseUnit);
                        
                        return Text(
                          'Estimasi HPP: Rp ${baseCost.toStringAsFixed(2)} per $_selectedBaseUnit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          _existingIngredient == null ? 'Simpan Bahan Baku' : 'Perbarui Bahan Baku',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}
