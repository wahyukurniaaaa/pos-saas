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
import '../../providers/cart_notes_provider.dart';
import '../../providers/selected_customer_provider.dart';
import '../../providers/split_payment_provider.dart';

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
  final TextEditingController _notesController = TextEditingController();
  Customer? _selectedCustomer;

  // Loyalty
  bool _usePoints = false;

  // Quick cash options
  late List<double> _quickCashOptions;

  // Processing & split mode flags
  bool _isProcessing = false;
  bool _isSplitMode = false;

  @override
  void initState() {
    super.initState();
    _calculateQuickCash(widget.totalAmount);
    // Initialize notes from provider
    final savedNotes = ref.read(cartNotesProvider);
    if (savedNotes != null) {
      _notesController.text = savedNotes;
    }

    // Initialize customer info from providers (restored from resumeBill or previous state)
    final savedCustomer = ref.read(selectedCustomerProvider);
    if (savedCustomer != null) {
      _selectedCustomer = savedCustomer;
      _nameController.text = savedCustomer.name;
      _phoneController.text = savedCustomer.phone ?? '';
    } else {
      final mName = ref.read(manualCustomerNameProvider);
      if (mName != null) _nameController.text = mName;
      final mPhone = ref.read(manualCustomerPhoneProvider);
      if (mPhone != null) _phoneController.text = mPhone;
    }

    // Reset split payment state when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splitPaymentProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _notesController.dispose();
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
    
    // If called from addPostFrameCallback or other places, ensure UI updates
    if (mounted) {
      setState(() {});
    }
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
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            maxWidth: MediaQuery.sizeOf(context).width > 768
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Metode Pembayaran',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          // Split mode toggle
                          GestureDetector(
                            onTap: () => setState(() => _isSplitMode = !_isSplitMode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isSplitMode
                                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.call_split_rounded,
                                    size: 14,
                                    color: _isSplitMode ? AppTheme.primaryColor : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Split',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _isSplitMode ? AppTheme.primaryColor : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (!_isSplitMode) ..._buildSinglePaymentSection(finalTotal),
                      if (_isSplitMode) _buildSplitPaymentSection(finalTotal, ref),

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
                      const SizedBox(height: 24),
                      _buildNotesSection(),
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
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : () => _handleHoldBill(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Simpan',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          // Determine if payment is complete
                          bool canPay;
                          if (_isSplitMode) {
                            final splitNotifier = ref.read(splitPaymentProvider.notifier);
                            canPay = splitNotifier.isComplete(finalTotal) && !_isProcessing;
                          } else {
                            canPay = (_cashReceived >= finalTotal || _selectedMethod != 'Tunai') && !_isProcessing;
                          }
                          if (!canPay) return;
                          _processPayment(finalTotal, taxAmount, serviceCharge, pointsEarned, pointsToRedeem);
                        },
                        // Disable logic
                        // ignore: avoid_positional_boolean_parameters
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
                                'Bayar & Cetak',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
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

  /// Wraps the existing single-method chips + cash/non-cash views.
  List<Widget> _buildSinglePaymentSection(double finalTotal) {
    return [
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
      if (_selectedMethod == 'Tunai') _buildCashSection(finalTotal),
      if (_selectedMethod != 'Tunai') _buildNonCashSection(),
    ];
  }

  /// Split payment UI with per-method rows and a remaining balance progress bar.
  Widget _buildSplitPaymentSection(double finalTotal, WidgetRef ref) {
    final splitEntries = ref.watch(splitPaymentProvider);
    final splitNotifier = ref.read(splitPaymentProvider.notifier);
    final totalPaid = splitNotifier.totalPaid;
    final remaining = splitNotifier.remaining(finalTotal);
    final isComplete = remaining <= 0;
    final progress = (totalPaid / finalTotal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isComplete
                ? AppTheme.successColor.withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isComplete
                  ? AppTheme.successColor.withValues(alpha: 0.4)
                  : AppTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isComplete ? '✓ Lunas' : 'Sisa Tagihan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isComplete ? AppTheme.successColor : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    isComplete ? 'Rp 0' : _currency.format(remaining),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isComplete ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? AppTheme.successColor : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment rows
        ...splitEntries.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return _buildSplitPaymentRow(idx, item, remaining, splitNotifier, splitEntries.length);
        }),

        const SizedBox(height: 12),

        // Add method button
        if (splitNotifier.canAddMore)
          GestureDetector(
            onTap: () {
              splitNotifier.addPayment(
                PaymentEntry(method: kSplitPaymentMethods.first, amount: remaining.clamp(0, double.infinity)),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    'Tambah Metode (${splitEntries.length}/$kMaxSplitMethods)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSplitPaymentRow(
    int index,
    PaymentEntry entry,
    double remaining,
    SplitPaymentNotifier notifier,
    int totalRows,
  ) {
    IconData methodIcon(String m) {
      switch (m.toLowerCase()) {
        case 'qris': return Icons.qr_code_2_rounded;
        case 'debit': return Icons.credit_card_rounded;
        case 'kredit': return Icons.credit_score_rounded;
        default: return Icons.payments_outlined;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Method selector
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: entry.method,
                  isExpanded: true,
                  icon: Icon(Icons.expand_more_rounded, color: AppTheme.primaryColor, size: 18),
                  items: kSplitPaymentMethods.map((m) {
                    return DropdownMenuItem(
                      value: m,
                      child: Row(
                        children: [
                          Icon(methodIcon(m), size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 6),
                          Text(m, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) notifier.updatePayment(index, entry.copyWith(method: val));
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Amount input
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: entry.amount > 0 ? entry.amount.toStringAsFixed(0) : '',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
              onChanged: (val) {
                final amount = double.tryParse(val) ?? 0;
                notifier.updatePayment(index, entry.copyWith(amount: amount));
              },
            ),
          ),
          const SizedBox(width: 8),
          // Delete row (only when >1 row)
          if (totalRows > 1)
            GestureDetector(
              onTap: () => notifier.removePayment(index),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.errorColor),
              ),
            )
          else
            const SizedBox(width: 34),
        ],
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
          createdAt: drift.Value(DateTime.now()),
          updatedAt: drift.Value(DateTime.now()),
        ),
      );
      
      final newCustomer = await (db.select(db.customers)..where((c) => c.id.equals(id))).getSingle();
      
      if (mounted) {
        setState(() {
          _selectedCustomer = newCustomer;
        });
        // Sync with provider
        ref.read(selectedCustomerProvider.notifier).state = newCustomer;
        ref.read(manualCustomerNameProvider.notifier).state = null;
        ref.read(manualCustomerPhoneProvider.notifier).state = null;
        
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

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _phoneController.clear();
      _nameController.clear();
      _usePoints = false;
    });
    // Sync with provider
    ref.read(selectedCustomerProvider.notifier).state = null;
    ref.read(manualCustomerNameProvider.notifier).state = null;
    ref.read(manualCustomerPhoneProvider.notifier).state = null;
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Informasi Pelanggan (CRM)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            if (_selectedCustomer != null)
              TextButton.icon(
                onPressed: _clearCustomer,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: Text('Ganti', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _selectedCustomer != null
            ? _buildSelectedCustomerCard(_selectedCustomer!)
            : _buildCustomerInputForm(showSuggestions, suggestions),
      ],
    );
  }

  Widget _buildSelectedCustomerCard(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.successColor.withValues(alpha: 0.1),
            child: Text(
              customer.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                ),
                Text(
                  customer.phone ?? 'Tidak ada nomor WhatsApp',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text('Poin', style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary)),
                Text(
                  customer.points.toString(),
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInputForm(bool showSuggestions, List<Customer> suggestions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Column(
        children: [
          // WhatsApp Phone Field with Auto-Match
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            onChanged: (val) {
              // Sync with provider
              ref.read(manualCustomerPhoneProvider.notifier).state = val.isEmpty ? null : val;
              
              if (val.length >= 8) {
                // Smart Auto-Match: Look for exact phone match in existing customers
                final customers = ref.read(customerProvider).value ?? [];
                final match = customers.where((c) => c.phone == val).toList();
                if (match.isNotEmpty) {
                  setState(() {
                    _selectedCustomer = match.first;
                    _nameController.text = match.first.name;
                    FocusScope.of(context).unfocus();
                  });
                  // Sync selection with provider
                  ref.read(selectedCustomerProvider.notifier).state = match.first;
                  return;
                }
              }
              setState(() {});
            },
            decoration: _inputCRMDeco('Nomor WhatsApp', Icons.phone_android_rounded, '0812...'),
          ),
          const SizedBox(height: 16),
          // Name Field
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            onChanged: (val) {
              // Sync with provider
              ref.read(manualCustomerNameProvider.notifier).state = val.isEmpty ? null : val;
              setState(() {});
            },
            decoration: _inputCRMDeco('Nama Pelanggan (Opsional)', Icons.person_add_alt_1_rounded, 'Budi Santoso'),
          ),

          // Suggestion List
          if (showSuggestions && suggestions.isNotEmpty)
            _buildSuggestionsList(suggestions),

          // No Member Found Message
          if (showSuggestions && suggestions.isEmpty)
            _buildNoMemberPrompt(),

          // Registration Action
          if (_selectedCustomer == null && (_nameController.text.isNotEmpty || _phoneController.text.isNotEmpty))
            _buildRegisterAction(),
        ],
      ),
    );
  }

  InputDecoration _inputCRMDeco(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: AppTheme.tertiaryColor, size: 20),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.tertiaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildSuggestionsList(List<Customer> suggestions) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade50, height: 1),
        itemBuilder: (context, index) {
          final option = suggestions[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(option.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ),
            title: Text(option.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: option.phone != null
                ? Text(option.phone!, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary))
                : null,
            onTap: () {
              setState(() {
                _selectedCustomer = option;
                _phoneController.text = option.phone ?? '';
                _nameController.text = option.name;
              });
              // Sync with providers
              ref.read(selectedCustomerProvider.notifier).state = option;
              ref.read(manualCustomerNameProvider.notifier).state = null;
              ref.read(manualCustomerPhoneProvider.notifier).state = null;
              
              FocusScope.of(context).unfocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildNoMemberPrompt() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(Icons.help_outline_rounded, color: AppTheme.textSecondary, size: 14),
          const SizedBox(width: 8),
          Text('Klik di bawah untuk daftarkan member baru',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRegisterAction() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: IntrinsicWidth(
        child: InkWell(
          onTap: _saveNewCustomer,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_rounded, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text(
                  'Daftarkan Sebagai Member Baru',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan Khusus',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 2,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Tambahkan catatan untuk pesanan ini...',
            hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.note_alt_rounded, color: AppTheme.primaryColor),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleHoldBill() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final shiftAsync = ref.read(openShiftProvider);
      final shiftOpt = shiftAsync.value;
      if (shiftOpt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada shift yang terbuka!')),
        );
        return;
      }

      final transactionId = await ref.read(cartProvider.notifier).holdBill(
            shiftId: shiftOpt.id,
            customerName: _nameController.text.trim().isNotEmpty 
                ? _nameController.text.trim() 
                : null,
            customerId: _selectedCustomer?.id,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
          );

      if (!mounted) return;

      if (transactionId != null) {
        Navigator.pop(context); // Close Payment Modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pesanan berhasil disimpan sementara.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan pesanan.')),
        );
      }
    } catch (e) {
      debugPrint('Hold bill error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
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

      String? assignedCustomerId = _selectedCustomer?.id;
      final enteredName = _nameController.text.trim();
      final enteredPhone = _phoneController.text.trim();

      // Build payment entries: Split mode vs. single mode
      final List<PaymentEntry> payments;
      if (_isSplitMode) {
        payments = ref.read(splitPaymentProvider);
      } else {
        // Single mode: wrap into one PaymentEntry
        final amount = _selectedMethod == 'Tunai' ? _cashReceived : finalTotal;
        payments = [PaymentEntry(method: _selectedMethod, amount: amount)];
      }

      // Determine change for success screen (cash only)
      final double changeAmount;
      if (!_isSplitMode && _selectedMethod == 'Tunai') {
        changeAmount = _getChange(finalTotal);
      } else if (_isSplitMode) {
        final splitNotifier = ref.read(splitPaymentProvider.notifier);
        changeAmount = splitNotifier.changeFor(finalTotal);
      } else {
        changeAmount = 0;
      }

      final String displayMethod = _isSplitMode
          ? payments.map((p) => p.method).join(' + ')
          : _selectedMethod;

      // 1. Process Checkout in Database
      final transactionId = await ref
          .read(cartProvider.notifier)
          .checkout(
            shiftId: shiftId,
            payments: payments,
            taxAmount: tax,
            serviceCharge: service,
            customerPhone: enteredPhone.isNotEmpty ? enteredPhone : null,
            customerName: enteredName.isNotEmpty ? enteredName : null,
            customerId: assignedCustomerId,
            notes: _notesController.text.trim().isNotEmpty
                ? _notesController.text.trim()
                : null,
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
              cashReceived: _isSplitMode
                  ? finalTotal + changeAmount
                  : (_selectedMethod == 'Tunai' ? _cashReceived : finalTotal),
              changeAmount: changeAmount,
              paymentMethod: displayMethod,
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
    } catch (e) {
      debugPrint('Process payment error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
