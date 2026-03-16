import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class SalesAnalyticsScreen extends ConsumerStatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  ConsumerState<SalesAnalyticsScreen> createState() =>
      _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends ConsumerState<SalesAnalyticsScreen> {
  String _selectedRange =
      'Bulan Ini'; // 'Hari Ini', '7 Hari Terakhir', 'Bulan Ini', 'Tahun Ini'

  bool _isLoading = true;
  int _totalRevenue = 0;
  int _totalTransactions = 0;
  int _aov = 0;
  double _revenueChange = 0; // percentage
  double _transactionChange = 0; // percentage
  List<ProductSales> _topProducts = [];
  List<DailySales> _salesData = []; // Can be hourly, daily, or monthly
  List<PaymentMethodSales> _paymentMethods = [];

  final _currency = NumberFormat.currency(
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
          // day 0 of next month is the last day of this month
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
    }
  }

  DateTimeRange _getPreviousDateRange(DateTimeRange current) {
    final duration = current.end.difference(current.start);
    final start = current.start.subtract(duration).subtract(const Duration(seconds: 1));
    final end = current.start.subtract(const Duration(seconds: 1));
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final range = _getDateRange();
    final prevRange = _getPreviousDateRange(range);

    final revenue = await db.getTotalRevenue(range.start, range.end);
    final count = await db.getTotalTransactions(range.start, range.end);
    final topProducts = await db.getTopProducts(range.start, range.end);
    final paymentMethods = await db.getPaymentMethodBreakdown(range.start, range.end);
    
    // Previous data for comparison
    final prevRevenue = await db.getTotalRevenue(prevRange.start, prevRange.end);
    final prevCount = await db.getTotalTransactions(prevRange.start, prevRange.end);

    // Dynamic sales trend
    List<DailySales> sales;
    if (_selectedRange == 'Hari Ini') {
      sales = await db.getHourlySales(range.start, range.end);
    } else if (_selectedRange == 'Tahun Ini') {
      // Need getMonthlySales? Or just use getDailySales and group in UI?
      // Let's just use getDailySales for now and group manually if needed, 
      // but I added getHourlySales to db. Let's add getMonthlySales to db later if needed.
      sales = await db.getDailySales(range.start, range.end);
    } else {
      sales = await db.getDailySales(range.start, range.end);
    }

    // --- DUMMY DATA INJECTION (FOR TESTING) ---
    // Dipanggil hanya jika database masih kosong untuk periode ini.
    // if (revenue == 0 && count == 0 && mounted) {
    //   _injectDummyData(range);
    //   return;
    // }

    if (mounted) {
      setState(() {
        _totalRevenue = revenue;
        _totalTransactions = count;
        _aov = count > 0 ? (revenue / count).round() : 0;
        _revenueChange = prevRevenue > 0 ? ((revenue - prevRevenue) / prevRevenue) * 100 : 0;
        _transactionChange = prevCount > 0 ? ((count - prevCount) / prevCount) * 100 : 0;
        _topProducts = topProducts;
        _salesData = sales;
        _paymentMethods = paymentMethods;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analitik Penjualan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppTheme.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 700;
          return ResponsiveCenter(
            maxWidth: 1024,
            child: Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _buildSummaryGrid(),
                              const SizedBox(height: 16),
                              if (isTablet)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: _buildChartCard()),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: _buildPaymentMethodsCard()),
                                  ],
                                )
                              else ...[
                                _buildChartCard(),
                                const SizedBox(height: 16),
                                _buildPaymentMethodsCard(),
                              ],
                              const SizedBox(height: 16),
                              if (isTablet)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildTopProductsCard()),
                                    const Spacer(), // Memberi ruang kosong di tablet agar tidak terlalu lebar
                                  ],
                                )
                              else
                                _buildTopProductsCard(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Hari Ini', '7 Hari Terakhir', 'Bulan Ini', 'Tahun Ini'].map((range) {
            final isSelected = _selectedRange == range;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(range),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedRange = range);
                    _loadData();
                  }
                },
                selectedColor: AppTheme.primaryColor,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMiniSummaryCard(
                'Total Pendapatan',
                _currency.format(_totalRevenue),
                _revenueChange,
                Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniSummaryCard(
                'Total Transaksi',
                '$_totalTransactions Trx',
                _transactionChange,
                Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildWideSummaryCard(
          'Average Order Value (AOV)',
          _currency.format(_aov),
          Icons.analytics_outlined,
          'Rata-rata belanja per pelanggan',
        ),
      ],
    );
  }

  Widget _buildMiniSummaryCard(String title, String value, double change, IconData icon) {
    final isPositive = change >= 0;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: AppTheme.textSecondary),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideSummaryCard(String title, String value, IconData icon, String subtitle) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    if (_salesData.isEmpty) return const SizedBox.shrink();

    final spots = _salesData.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalAmount.toDouble());
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tren Penjualan ($_selectedRange)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.backgroundLight,
                      strokeWidth: 1,
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppTheme.primaryColor,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            _formatCompact(spot.y),
                            GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) => Text(
                          _formatCompact(value),
                          style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1, // Kita kontrol manual di getTitlesWidget
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < _salesData.length) {
                            // Hitung interval agar tidak tumpuk (Hari ini tiap 4 jam, Bulan ini tiap 6 hari)
                            int showEvery = _selectedRange == 'Hari Ini' ? 4 : 6;
                            
                            if (index % showEvery != 0 && index != _salesData.length - 1) {
                              return const SizedBox.shrink();
                            }

                            // Ambil teks asli (misal 12/03), jika mode bulanan ambil angka depannya saja (12)
                            String label = _salesData[index].dateStr;
                            if (_selectedRange != 'Hari Ini' && label.contains('/')) {
                              label = label.split('/').first; // Ambil tanggalnya saja
                            }

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 8,
                              child: Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.2),
                            AppTheme.primaryColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}rb';
    if (value == 0) return '0';
    return value.toInt().toString();
  }

  Color _getPaymentColor(int index) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      const Color(0xFF6366F1), // Indigo
      AppTheme.successColor,
      const Color(0xFFEC4899), // Pink
    ];
    return colors[index % colors.length];
  }

  Widget _buildPaymentMethodsCard() {
    if (_paymentMethods.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metode Pembayaran',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: _paymentMethods.asMap().entries.map((e) {
                         return PieChartSectionData(
                           color: _getPaymentColor(e.key),
                           value: e.value.totalAmount.toDouble(),
                           title: '',
                           radius: 15,
                         );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: _paymentMethods.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(
                              color: _getPaymentColor(e.key),
                              shape: BoxShape.circle,
                            )),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value.method.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12))),
                            Text('${((e.value.totalAmount / _totalRevenue) * 100).toStringAsFixed(0)}%', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top 5 Produk (Kuantitas)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_topProducts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Belum ada data',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ..._topProducts.asMap().entries.map(
                (entry) {
                   final p = entry.value;
                   final maxQty = _topProducts.first.totalQuantity;
                   final progress = p.totalQuantity / maxQty;
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 16),
                     child: Column(
                       children: [
                         Row(
                           children: [
                             Text('${entry.key + 1}', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                             const SizedBox(width: 12),
                             Expanded(child: Text(p.productName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                             Text('${p.totalQuantity}x', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                           ],
                         ),
                         const SizedBox(height: 6),
                         ClipRRect(
                           borderRadius: BorderRadius.circular(4),
                           child: LinearProgressIndicator(
                             value: progress,
                             backgroundColor: AppTheme.backgroundLight,
                             color: AppTheme.primaryColor,
                             minHeight: 6,
                           ),
                         ),
                       ],
                     ),
                   );
                }
              ),
          ],
        ),
      ),
    );
  }

}
