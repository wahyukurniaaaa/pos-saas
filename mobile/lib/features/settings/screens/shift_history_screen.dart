import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/features/pos/providers/shift_provider.dart';
import 'package:posify_app/features/pos/screens/shift/shift_opening_modal.dart';
import 'package:posify_app/features/pos/screens/shift/shift_report_modal.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

class ShiftHistoryScreen extends ConsumerWidget {
  const ShiftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Riwayat Sesi Shift',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, child) {
          final activeShift = ref.watch(openShiftProvider).value;
          final hasOpenShift = activeShift != null;
          
          return FloatingActionButton.extended(
            onPressed: () {
              if (hasOpenShift) {
                final session = ref.read(sessionProvider).value;
                final cashierName = session?.name ?? 'Kasir';
                
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => ShiftReportModal(
                    cashierName: cashierName, 
                    focusCloseShift: true,
                  ),
                );
              } else {
                showDialog(
                  context: context,
                  builder: (context) => const ShiftOpeningModal(),
                );
              }
            },
            icon: Icon(hasOpenShift ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
            label: Text(
              hasOpenShift ? 'Tutup Kasir' : 'Buka Kasir',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: hasOpenShift ? AppTheme.dangerColor : AppTheme.secondaryColor,
            foregroundColor: hasOpenShift ? Colors.white : AppTheme.primaryColor,
          );
        },
      ),
      body: ResponsiveCenter(child: StreamBuilder<List<ShiftWithEmployee>>(
        stream: db.watchAllShifts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat shift',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final shift = entry.shift;
              final employee = entry.employee;
              final isOpen = shift.status == 'open';

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isOpen
                        ? AppTheme.successColor.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? AppTheme.successColor.withValues(alpha: 0.1)
                                  : AppTheme.textSecondary.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isOpen ? Icons.lock_open : Icons.lock,
                              size: 20,
                              color: isOpen
                                  ? AppTheme.successColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  employee.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateFmt.format(shift.startTime),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? AppTheme.successColor.withValues(alpha: 0.1)
                                  : AppTheme.textSecondary.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpen ? 'BUKA' : 'TUTUP',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOpen
                                    ? AppTheme.successColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              'Kas Awal',
                              currency.format(shift.startingCash),
                            ),
                          ),
                          Expanded(
                            child: _buildInfoItem(
                              'Kas Sistem',
                              currency.format(shift.expectedEndingCash ?? shift.startingCash),
                            ),
                          ),
                          if (shift.actualEndingCash != null)
                            Expanded(
                              child: _buildInfoItem(
                                'Kas Fisik',
                                currency.format(shift.actualEndingCash!),
                              ),
                            ),
                        ],
                      ),
                      if (shift.endTime != null) ...[
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (shift.actualEndingCash != null && shift.expectedEndingCash != null)
                              Expanded(
                                child: _buildInfoItem(
                                  'Selisih',
                                  _formatDiscrepancy(shift.actualEndingCash!, shift.expectedEndingCash!, currency),
                                  valueColor: _getDiscrepancyColor(shift.actualEndingCash!, shift.expectedEndingCash!),
                                ),
                              ),
                            Expanded(
                              child: _buildInfoItem(
                                'Waktu Tutup',
                                dateFmt.format(shift.endTime!),
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'Durasi',
                                _calculateDuration(shift.startTime, shift.endTime!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      )),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13, 
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDiscrepancy(int actual, int expected, NumberFormat currency) {
    final diff = actual - expected;
    if (diff > 0) return '+${currency.format(diff)}';
    if (diff < 0) return currency.format(diff);
    return 'Rp 0';
  }

  Color _getDiscrepancyColor(int actual, int expected) {
    final diff = actual - expected;
    if (diff > 0) return AppTheme.successColor;
    if (diff < 0) return AppTheme.dangerColor;
    return AppTheme.textPrimary;
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
  }
}
