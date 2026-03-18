import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import '../providers/store_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class TaxServiceSettingsScreen extends ConsumerStatefulWidget {
  const TaxServiceSettingsScreen({super.key});

  @override
  ConsumerState<TaxServiceSettingsScreen> createState() =>
      _TaxServiceSettingsScreenState();
}

class _TaxServiceSettingsScreenState
    extends ConsumerState<TaxServiceSettingsScreen> {
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();
  String _taxType = 'exclusive';
  bool _isInit = false;

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final tax = int.tryParse(_taxController.text) ?? 0;
    final service = int.tryParse(_serviceController.text) ?? 0;

    final success = await ref
        .read(storeControllerProvider.notifier)
        .updateTaxAndService(
          taxPercentage: tax,
          taxType: _taxType,
          serviceChargePercentage: service,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil disimpan')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan pengaturan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeAsync = ref.watch(storeProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pajak & Service Charge',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ResponsiveCenter(child: storeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile != null && !_isInit) {
            _taxController.text = profile.taxPercentage.toString();
            _serviceController.text = profile.serviceChargePercentage
                .toString();
            _taxType = profile.taxType;
            _isInit = true;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle('Pajak (PPN/PB1)'),
              const SizedBox(height: 12),
              TextField(
                controller: _taxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Persentase Pajak (%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Tipe Pajak'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Exclusive (Add-on)',
                      value: 'exclusive',
                      selected: _taxType == 'exclusive',
                      onSelected: (val) =>
                          setState(() => _taxType = 'exclusive'),
                      description: 'Pajak ditambahkan di akhir total belanja.',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChoiceChip(
                      label: 'Inclusive (All-in)',
                      value: 'inclusive',
                      selected: _taxType == 'inclusive',
                      onSelected: (val) =>
                          setState(() => _taxType = 'inclusive'),
                      description: 'Harga produk sudah termasuk pajak.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Service Charge'),
              const SizedBox(height: 12),
              TextField(
                controller: _serviceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Persentase Layanan (%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: ref.watch(storeControllerProvider.select((s) => s.isLoading))
                      ? null
                      : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: ref.watch(storeControllerProvider.select((s) => s.isLoading))
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Simpan Pengaturan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      )),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required String value,
    required bool selected,
    required Function(bool) onSelected,
    required String description,
  }) {
    return InkWell(
      onTap: () => onSelected(true),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: selected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
