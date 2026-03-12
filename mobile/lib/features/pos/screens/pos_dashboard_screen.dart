import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'pos_tab.dart';
import 'inventory_tab.dart';
import 'settings_tab.dart';
import 'current_shift_history_tab.dart';

class PosDashboardScreen extends ConsumerStatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  ConsumerState<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends ConsumerState<PosDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Soft background for Stitch style
      body: IndexedStack(
        index: _currentTabIndex,
        children: const [
          PosTab(),
          CurrentShiftHistoryTab(),
          InventoryTab(),
          SettingsTab()
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (i) => setState(() => _currentTabIndex = i),
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.point_of_sale_rounded),
              ),
              label: 'Kasir',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.receipt_long_rounded),
              ),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.inventory_2_rounded),
              ),
              label: 'Stok',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.settings_rounded),
              ),
              label: 'Setting',
            ),
          ],
        ),
      ),
    );
  }
}
