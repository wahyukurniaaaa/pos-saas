import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class StockLossReportScreen extends ConsumerStatefulWidget {
  const StockLossReportScreen({super.key});

  @override
  ConsumerState<StockLossReportScreen> createState() => _StockLossReportScreenState();
}

class _StockLossReportScreenState extends ConsumerState<StockLossReportScreen> {
  String _selectedRange = 'Bulan Ini'; 
  bool _isLoading = true;
  List<StockLossItem> _lossItems = [];
  int _totalLossValue = 0;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case 'Hari Ini':
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case '7 Hari Terakhir':
        final start = now.subtract(const Duration(days: 7));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case 'Tahun Ini':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case 'Bulan Ini':
      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final range = _getDateRange();

    try {
      final items = await db.getStockLossReport(range.start, range.end);
      
      int totalValue = 0;
      for (var i in items) {
        totalValue += i.lossValue;
      }

      if (mounted) {
        setState(() {
          _lossItems = items;
          _totalLossValue = totalValue;
        });
      }
    } catch (e) {
      debugPrint('Error loading stock loss report: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pilih Periode',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildFilterOption('Hari Ini'),
              _buildFilterOption('7 Hari Terakhir'),
              _buildFilterOption('Bulan Ini'),
              _buildFilterOption('Tahun Ini'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String range) {
    final isSelected = _selectedRange == range;
    return ListTile(
      title: Text(
        range,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
          : null,
      onTap: () {
        Navigator.pop(context);
        setState(() => _selectedRange = range);
        _loadData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Laporan Pemborosan Stok',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Header with Filter & Total Loss
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Filter Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _showFilterModal,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              _selectedRange,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Total Value
                  Text(
                    'Total Kerugian/Pemborosan',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormat.format(_totalLossValue),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _lossItems.isEmpty
                      ? _buildEmptyState()
                      : _buildLossList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Tidak Ada Pemborosan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada kerugian stok pada periode ini',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLossList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _lossItems.length,
      itemBuilder: (context, index) {
        final item = _lossItems[index];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.type == 'INGREDIENT'
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.type == 'INGREDIENT' ? Icons.kitchen : Icons.inventory_2,
                    color: item.type == 'INGREDIENT' ? Colors.orange : Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Alasan: ${item.reason}',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jumlah: ${item.varianceQuantity.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rugi',
                      style: GoogleFonts.poppins(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _currencyFormat.format(item.lossValue),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
