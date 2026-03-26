import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/shift_provider.dart';
import 'package:posify_app/features/settings/providers/store_provider.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import '../../providers/pos_providers.dart';
import '../../providers/discount_provider.dart';
import 'discount_selection_sheet.dart';
import 'payment_success_screen.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class PaymentModal extends ConsumerStatefulWidget {
  final double totalAmount;

  const PaymentModal({super.key, required this.totalAmount});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  String _selectedMethod = 'Tunai';

  // Numpad state for manual entry
  String _cashReceivedString = '';

  // Customer info controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  Customer? _selectedCustomer;

  // Loyalty
  bool _usePoints = false;

  // Quick cash options
  late List<double> _quickCashOptions;

  @override
  void initState() {
    super.initState();
    _calculateQuickCash(widget.totalAmount);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _calculateQuickCash(double amount) {
    // Generate quick cash buttons based on amount
    _quickCashOptions = [amount]; // always exact amount first

    // Add next rounding up visually (simplified)
    if (amount < 50000) {
      _quickCashOptions.add(50000);
      _quickCashOptions.add(100000);
    } else if (amount < 100000) {
      _quickCashOptions.add(100000);
      _quickCashOptions.add(150000);
    } else {
      double nextHundred = ((amount / 100000).ceil()) * 100000;
      if (nextHundred == amount) nextHundred += 50000;

      _quickCashOptions.add(nextHundred);
      _quickCashOptions.add(nextHundred + 50000);
    }

    // Default to Uang Pas
    _cashReceivedString = amount.toStringAsFixed(0);
  }

  double get _cashReceived {
    if (_cashReceivedString.isEmpty) return 0;
    return double.tryParse(_cashReceivedString) ?? 0;
  }

  double _getChange(double finalTotal) {
    double received = _cashReceived;
    if (received < finalTotal) return 0;
    return received - finalTotal;
  }

  void _onNumpadPress(String digit) {
    setState(() {
      if (digit == 'C') {
        _cashReceivedString = '';
      } else if (digit == '000') {
        if (_cashReceivedString.isNotEmpty) {
          _cashReceivedString += '000';
        }
      } else if (digit == 'DEL') {
        if (_cashReceivedString.isNotEmpty) {
          _cashReceivedString = _cashReceivedString.substring(
            0,
            _cashReceivedString.length - 1,
          );
        }
      } else {
        if (_cashReceivedString == '0' ||
            _cashReceivedString == widget.totalAmount.toStringAsFixed(0)) {
          // Clear if it's 0 or the exact amount (uamg pas generated value)
          _cashReceivedString = digit;
        } else {
          _cashReceivedString += digit;
        }
      }
    });
  }

  void _onQuickCashPress(double amount) {
    setState(() {
      _cashReceivedString = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final validDiscountsAsync = ref.watch(validTransactionDiscountsProvider(widget.totalAmount));
    if (validDiscountsAsync.hasValue) {
      ref.read(selectedDiscountProvider.notifier).autoApplyIfNeeded(
        validDiscountsAsync.value!, 
        widget.totalAmount
      );
    }

    final storeAsync = ref.watch(storeProfileProvider);

    return storeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (profile) {
        final taxPercentage = profile?.taxPercentage ?? 0;
        final taxType = profile?.taxType ?? 'exclusive';
        final servicePercentage = profile?.serviceChargePercentage ?? 0;
        
        final loyaltyPointConversion = profile?.loyaltyPointConversion ?? 10000;
        final loyaltyPointValue = profile?.loyaltyPointValue ?? 100;

        double serviceCharge = 0;
        double taxAmount = 0;
        double finalTotal = widget.totalAmount;

        // Discount calculation
        final selectedDiscount = ref.watch(selectedDiscountProvider);
        int discountAmount = 0;
        if (selectedDiscount != null) {
          discountAmount = calculateDiscountAmount(selectedDiscount, widget.totalAmount.toInt());
        }

        // Points calculation
        int pointsDiscount = 0;
        int pointsToRedeem = 0;
        if (_usePoints && _selectedCustomer != null) {
          final currentPoints = _selectedCustomer!.points;
          final subtotalAfterDiscount = widget.totalAmount - discountAmount;
          final maxUsablePoints = (subtotalAfterDiscount / loyaltyPointValue).floor();
          
          pointsToRedeem = currentPoints > maxUsablePoints ? maxUsablePoints : currentPoints;
          pointsDiscount = pointsToRedeem * loyaltyPointValue;
        }

        if (taxType == 'exclusive') {
          serviceCharge = widget.totalAmount * (servicePercentage / 100);
          taxAmount = (widget.totalAmount + serviceCharge) * (taxPercentage / 100);
          finalTotal = widget.totalAmount + serviceCharge + taxAmount - discountAmount - pointsDiscount;
        } else {
          finalTotal = widget.totalAmount - discountAmount - pointsDiscount;
          taxAmount = finalTotal - (finalTotal / (1 + (taxPercentage / 100)));
          serviceCharge = 0;
        }
        
        if (finalTotal < 0) finalTotal = 0;

        final pointsEarned = (finalTotal / loyaltyPointConversion).floor();

        // Update quick cash options based on the calculated finalTotal
        // This needs to be done here because finalTotal depends on async data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_quickCashOptions.first != finalTotal) {
            _calculateQuickCash(finalTotal);
          }
        });

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: MediaQuery.of(context).size.width > 768
                ? 600
                : double.infinity,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pembayaran',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Total to Pay
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.tertiaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Tagihan',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currency.format(finalTotal),
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Discount Selection Row ──
                      _buildDiscountRow(context, ref, widget.totalAmount, selectedDiscount, discountAmount),
                      const SizedBox(height: 20),

                      // Payment Methods
                      Text(
                        'Metode Pembayaran',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildMethodChip('Tunai'),
                          const SizedBox(width: 8),
                          _buildMethodChip('QRIS'),
                          const SizedBox(width: 8),
                          _buildMethodChip('Debit'),
                          const SizedBox(width: 8),
                          _buildMethodChip('Kasbon'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Dynamic Content based on Method
                      if (_selectedMethod == 'Tunai')
                        _buildCashSection(finalTotal),
                      if (_selectedMethod != 'Tunai') _buildNonCashSection(),

                      const SizedBox(height: 24),
                      _buildCustomerInfoSection(),
                      const SizedBox(height: 16),
                      if (_selectedCustomer != null)
                        _buildLoyaltySection(
                          pointsEarned,
                          pointsToRedeem,
                          pointsDiscount,
                          _selectedCustomer!.points,
                          loyaltyPointValue,
                        ),
                    ],
                  ),
                ),
              ),

              // Action Bottom
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      (_cashReceived >= finalTotal ||
                              _selectedMethod != 'Tunai') &&
                          !_isProcessing
                      ? () => _processPayment(
                          finalTotal,
                          taxAmount,
                          serviceCharge,
                          pointsEarned,
                          pointsToRedeem,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Konfirmasi & Cetak Struk',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountRow(BuildContext context, WidgetRef ref,
      double subtotal, Discount? selected, int discountAmount) {
    return GestureDetector(
      onTap: () => showDiscountSelectionSheet(context, ref, subtotal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected != null
              ? AppTheme.secondaryColor.withOpacity(0.08)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected != null
                ? AppTheme.secondaryColor
                : Colors.grey.shade200,
            width: selected != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected != null
                    ? AppTheme.secondaryColor.withOpacity(0.2)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_offer_rounded,
                size: 20,
                color: selected != null
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: selected == null
                  ? Text(
                      'Pilih Promo / Voucher',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontSize: 14),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontSize: 14),
                        ),
                        Text(
                          'Hemat ${_currency.format(discountAmount)}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                              fontSize: 12),
                        ),
                      ],
                    ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodChip(String method) {
    final isSelected = _selectedMethod == method;
    IconData icon;
    switch (method) {
      case 'QRIS':
        icon = Icons.qr_code_2_rounded;
        break;
      case 'Debit':
        icon = Icons.credit_card_rounded;
        break;
      case 'Kasbon':
        icon = Icons.receipt_long_rounded;
        break;
      case 'Tunai':
      default:
        icon = Icons.payments_rounded;
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                method,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashSection(double finalTotal) {
    final change = _getChange(finalTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Received Amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Uang Diterima',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  _cashReceivedString.isEmpty ? '0' : _currency.format(_cashReceived),
                  textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Cash
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _quickCashOptions.map((amt) {
              final isExact = amt == finalTotal;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _onQuickCashPress(amt),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isExact ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(
                        color: isExact ? AppTheme.primaryColor : Colors.grey.shade200,
                        width: isExact ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isExact ? 'Uang Pas' : _currency.format(amt).replaceAll('Rp ', ''),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isExact ? AppTheme.primaryColor : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Numpad
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
            _buildKey(
              'C',
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              textColor: AppTheme.errorColor,
            ),
            _buildKey('0'),
            _buildKey('000'),
          ],
        ),

        const SizedBox(height: 24),

        // Change
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: change > 0
                ? AppTheme.neutralSlate.withValues(alpha: 0.1)
                : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: change > 0
                  ? AppTheme.neutralSlate.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kembalian',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: change > 0
                      ? AppTheme.neutralSlate
                      : AppTheme.textSecondary,
                ),
              ),
              Text(
                _currency.format(change),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: change > 0
                      ? AppTheme.neutralSlate
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String label, {Color? color, Color? textColor}) {
    final isAction = label == 'C' || label == 'DEL' || label == '000';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNumpadPress(label),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? (isAction ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : Theme.of(context).colorScheme.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: [
              if (!isAction)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: isAction ? 18 : 24,
                fontWeight: isAction ? FontWeight.w700 : FontWeight.w600,
                color: textColor ?? (isAction ? AppTheme.textSecondary : AppTheme.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNonCashSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(
            _selectedMethod == 'QRIS'
                ? Icons.qr_code_2
                : _selectedMethod == 'Debit'
                ? Icons.credit_card
                : Icons.edit_document,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Siapkan mesin EDC atau minta Pelanggan scan kode QR. Tekan Konfirmasi jika pembayaran berhasil.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNewCustomer() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama pelanggan wajib diisi!')),
      );
      return;
    }

    try {
      final db = ref.read(databaseProvider);
      final id = await db.insertCustomer(
        CustomersCompanion.insert(
          name: name,
          phone: drift.Value(phone.isNotEmpty ? phone : null),
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      
      final newCustomer = await (db.select(db.customers)..where((c) => c.id.equals(id))).getSingle();
      
      if (mounted) {
        setState(() {
          _selectedCustomer = newCustomer;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Member "$name" berhasil didaftarkan!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      ref.invalidate(customerProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan member: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Widget _buildCustomerInfoSection() {
    final customers = ref.watch(customerProvider).value ?? [];

    // Calculate suggestions based on text input and current selection
    final nQuery = _nameController.text.trim().toLowerCase();
    final pQuery = _phoneController.text.trim().toLowerCase();
    final showSuggestions = (nQuery.isNotEmpty || pQuery.isNotEmpty) && _selectedCustomer == null;
    
    final suggestions = showSuggestions
        ? customers.where((c) {
            bool matchName = nQuery.isEmpty || c.name.toLowerCase().contains(nQuery);
            bool matchPhone = pQuery.isEmpty || (c.phone != null && c.phone!.contains(pQuery));
            return matchName && matchPhone;
          }).take(4).toList()
        : <Customer>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informasi Pelanggan (CRM)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.1), width: 2),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                onChanged: (val) {
                  if (_selectedCustomer != null) {
                    _selectedCustomer = null; 
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Nomor WhatsApp',
                  labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.tertiaryColor),
                  hintText: '08123456789',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (val) {
                  if (_selectedCustomer != null) {
                    _selectedCustomer = null;
                  }
                  setState(() {});
                },
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: 'Nama Pelanggan / Member (Opsional)',
                  labelStyle: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.tertiary),
                  hintText: 'Budi Santoso',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.tertiary, width: 1.5),
                  ),
                ),
              ),
              if (_selectedCustomer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Member Terpilih: ${_selectedCustomer!.name}',
                        style: GoogleFonts.poppins(color: AppTheme.successColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              if (showSuggestions && suggestions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.textSecondary.withValues(alpha: 0.8), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Pencarian member: Tidak ditemukan',
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (showSuggestions && suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
                    itemBuilder: (context, index) {
                      final option = suggestions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          child: Text(
                            option.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                        title: Text(
                          option.name,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: option.phone != null
                            ? Text(option.phone!, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCustomer = option;
                            _phoneController.text = option.phone ?? '';
                            _nameController.text = option.name;
                          });
                          // Move focus away to collapse keyboard safely
                          FocusScope.of(context).unfocus();
                        },
                      );
                    },
                  ),
                ),
              if (_selectedCustomer == null && (_nameController.text.isNotEmpty || _phoneController.text.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton.icon(
                    onPressed: _saveNewCustomer,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text(
                      'Daftarkan Sebagai Member Baru',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              if (_selectedCustomer != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Member Terdaftar',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltySection(
    int pointsEarned,
    int pointsToRedeem,
    int pointsDiscount,
    int currentPoints,
    int loyaltyPointValue,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Loyalty Point',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+$pointsEarned Poin',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Poin Tersedia: $currentPoints',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
          ),
          if (currentPoints > 0) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tukar Poin',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '1 Poin = ${_currency.format(loyaltyPointValue)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _usePoints,
                  onChanged: (val) {
                    setState(() {
                      _usePoints = val;
                    });
                  },
                activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            ),
            if (_usePoints && pointsDiscount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Memotong $pointsToRedeem Poin (-${_currency.format(pointsDiscount)})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool _isProcessing = false;

  Future<void> _processPayment(
    double finalTotal,
    double tax,
    double service,
    int pointsEarned,
    int pointsToRedeem,
  ) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final changeAmount = _selectedMethod == 'Tunai'
          ? _getChange(finalTotal).toInt()
          : 0;
      final shiftOpt = ref.read(openShiftProvider).value;
      if (shiftOpt == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada shift yang terbuka!')),
        );
        setState(() => _isProcessing = false);
        return;
      }
      final shiftId = shiftOpt.id;
      // final subtotal = ref.read(cartProvider.notifier).subtotal; // No longer needed directly here

      // Custom Create Customer logic if they type name/phone but it's not selected
      int? assignedCustomerId = _selectedCustomer?.id;
      final enteredName = _nameController.text.trim();
      final enteredPhone = _phoneController.text.trim();
      
      if (assignedCustomerId == null && (enteredName.isNotEmpty || enteredPhone.isNotEmpty)) {
        // Create a new customer record automatically
      }
      
      // Customer is only saved if the user explicitly clicked the "Daftarkan Member Baru" button.
      // Otherwise, the name and phone are just attached to the transaction record without creating a Member.


      // 1. Process Checkout in Database
      final transactionId = await ref
          .read(cartProvider.notifier)
          .checkout(
            shiftId: shiftId,
            paymentMethod: _selectedMethod.toLowerCase(),
            taxAmount: tax,
            serviceCharge: service,
            customerPhone: enteredPhone.isNotEmpty ? enteredPhone : null,
            customerName: enteredName.isNotEmpty ? enteredName : null,
            customerId: assignedCustomerId,
            pointsEarned: pointsEarned,
            pointsRedeemed: pointsToRedeem,
            discountId: ref.read(selectedDiscountProvider)?.id,
            discountAmount: ref.read(selectedDiscountProvider) != null
                ? calculateDiscountAmount(
                    ref.read(selectedDiscountProvider)!,
                    ref.read(cartProvider.notifier).subtotal.toInt())
                : 0,
          );

      if (!mounted) return;

      if (transactionId != null) {
        // 2. Calculate new customer balance if applicable
        int? customerPointsAfter;
        if (_selectedCustomer != null && pointsEarned > 0) {
          final db = ref.read(databaseProvider);
          final updatedCustomer = await (db.select(db.customers)
              ..where((c) => c.id.equals(_selectedCustomer!.id))).getSingleOrNull();
          customerPointsAfter = updatedCustomer?.points;
        }

        if (!mounted) return;

        // 3. Tampilkan Layar Sukses
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(
              transactionId: transactionId,
              totalAmount: finalTotal,
              cashReceived: _selectedMethod == 'Tunai'
                  ? _cashReceived
                  : finalTotal,
              changeAmount: changeAmount.toDouble(),
              paymentMethod: _selectedMethod,
              pointsEarned: pointsEarned,
              customerPointsAfter: customerPointsAfter,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memproses pembayaran.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
