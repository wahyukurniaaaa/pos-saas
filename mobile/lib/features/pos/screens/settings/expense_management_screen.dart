import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/expense_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/providers/shift_provider.dart';
import 'package:drift/drift.dart' hide Column;

class ExpenseManagementScreen extends ConsumerStatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  ConsumerState<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState
    extends ConsumerState<ExpenseManagementScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset));
    });
    ref.read(expenseProvider.notifier).setDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Pengeluaran (Kas Keluar)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_rounded),
            tooltip: 'Kelola Kategori',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExpenseCategoryScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: AppTheme.primaryColor,
        onPressed: () => _showExpenseForm(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // ── Date navigator ──────────────────────────────────────
          _buildDateNav(),
          // ── Summary card ────────────────────────────────────────
          expenses.when(
            data: (list) => _buildSummaryCard(list),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: expenses.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => list.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _buildExpenseCard(list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNav() {
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeDate(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
          ),
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          IconButton(
            onPressed: isToday ? null : () => _changeDate(1),
            icon: Icon(Icons.chevron_right_rounded,
                color: isToday ? Colors.white38 : Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<ExpenseWithCategory> list) {
    final total = list.fold<int>(0, (sum, e) => sum + e.expense.amount);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_down_rounded, color: AppTheme.secondaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Pengeluaran Hari Ini',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              Text(_currency.format(total),
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
              Text('${list.length} entri',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseWithCategory item) {
    final category = item.category;
    final categoryColor = _parseColor(category?.color ?? '#7F8C8D');

    return Dismissible(
      key: Key('expense-${item.expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Pengeluaran?'),
            content: const Text('Data tidak dapat dikembalikan.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => ref.read(expenseProvider.notifier).delete(item.expense.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(category?.icon), color: categoryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category?.name ?? 'Lain-lain',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(_currency.format(item.expense.amount),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.errorColor,
                              fontSize: 15)),
                    ],
                  ),
                  if (item.expense.note != null)
                    Text(item.expense.note!,
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(DateFormat('HH:mm').format(item.expense.createdAt),
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: AppTheme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text('Belum ada pengeluaran',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
          Text('hari ini', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.textSecondary;
    }
  }

  IconData _getIcon(String? name) {
    const map = {
      'inventory_2': Icons.inventory_2_rounded,
      'people': Icons.people_rounded,
      'bolt': Icons.bolt_rounded,
      'build': Icons.build_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'restaurant': Icons.restaurant_rounded,
      'water_drop': Icons.water_drop_rounded,
      'local_shipping': Icons.local_shipping_rounded,
    };
    return map[name] ?? Icons.money_off_rounded;
  }

  void _showExpenseForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(selectedDate: _selectedDate),
    );
  }
}

// ── Expense Form Bottom Sheet ─────────────────────────────────────────────────

class _ExpenseFormSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  const _ExpenseFormSheet({required this.selectedDate});

  @override
  ConsumerState<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ExpenseCategory? _selectedCategory;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoryProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text('Tambah Pengeluaran',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount field
                    _sectionLabel('Nominal Pengeluaran *'),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 20),
                      decoration: InputDecoration(
                        prefixText: 'Rp  ',
                        prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        hintText: '0',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Category chips
                    _sectionLabel('Kategori *'),
                    categories.when(
                      data: (cats) => Wrap(
                        spacing: 8, runSpacing: 8,
                        children: cats.map((c) {
                          final selected = _selectedCategory?.id == c.id;
                          final color = _parseColor(c.color);
                          return ChoiceChip(
                            selected: selected,
                            label: Text(c.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppTheme.primaryColor : AppTheme.textSecondary)),
                            backgroundColor: Colors.grey.shade100,
                            selectedColor: AppTheme.secondaryColor.withOpacity(0.25),
                            side: BorderSide(color: selected ? AppTheme.secondaryColor : Colors.transparent),
                            avatar: Icon(_getIcon(c.icon), color: selected ? AppTheme.primaryColor : color, size: 16),
                            onSelected: (_) => setState(() => _selectedCategory = c),
                          );
                        }).toList(),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),
                    // Note
                    _sectionLabel('Keterangan (Opsional)'),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Misal: Belanja beras 5kg di pasar...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppTheme.secondaryColor, width: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Submit button
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Simpan Pengeluaran',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
  );

  Future<void> _submit() async {
    final amountStr = _amountCtrl.text.trim();
    if (amountStr.isEmpty || int.tryParse(amountStr) == null || int.parse(amountStr) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid.')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori pengeluaran.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final session = ref.read(sessionProvider).value;
      final employeeId = session?.id ?? '';
      final openShift = ref.read(openShiftProvider).value;
      await ref.read(expenseProvider.notifier).add(
        ExpensesCompanion.insert(
          categoryId: _selectedCategory!.id,
          recordedBy: employeeId,
          shiftId: Value(openShift?.id),
          amount: int.parse(amountStr),
          note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
          createdAt: Value(DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day,
              DateTime.now().hour, DateTime.now().minute)),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.textSecondary;
    }
  }

  IconData _getIcon(String? name) {
    const map = {
      'inventory_2': Icons.inventory_2_rounded,
      'people': Icons.people_rounded,
      'bolt': Icons.bolt_rounded,
      'build': Icons.build_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'restaurant': Icons.restaurant_rounded,
      'water_drop': Icons.water_drop_rounded,
    };
    return map[name] ?? Icons.money_off_rounded;
  }
}

// ── Expense Category Management Screen ────────────────────────────────────────

class ExpenseCategoryScreen extends ConsumerWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(expenseCategoryProvider);
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Kelola Kategori',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cats) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final c = cats[i];
            final color = _parseColor(c.color);
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(_getIcon(c.icon), color: color, size: 22),
                ),
                title: Text(c.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: c.isDefault
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Default',
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                      )
                    : IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                        onPressed: () => ref.read(expenseCategoryProvider.notifier).delete(c.id),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  IconData _getIcon(String? name) {
    const map = {
      'inventory_2': Icons.inventory_2_rounded,
      'people': Icons.people_rounded,
      'bolt': Icons.bolt_rounded,
      'build': Icons.build_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
    };
    return map[name] ?? Icons.money_off_rounded;
  }
}
