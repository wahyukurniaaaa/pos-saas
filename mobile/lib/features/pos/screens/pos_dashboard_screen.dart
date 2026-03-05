import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';

class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends State<PosDashboardScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [_buildPosTab(), _buildInventoryTab(), _buildSettingsTab()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (i) => setState(() => _currentTabIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Stok',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  // ===== POS TAB =====
  Widget _buildPosTab() {
    return Column(
      children: [
        // App Bar
        Container(
          color: AppTheme.primaryColor,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Top bar
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kasir',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                          color: AppTheme.successColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.successColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Shift Buka',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.search,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cari Produk / Scan...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.all(4),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child: Row(
            children: [
              // Product Grid
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Category tabs
                    Container(
                      height: 44,
                      color: Colors.white,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        children: [
                          _buildCategoryChip('⭐ Populer', true),
                          _buildCategoryChip('🍜 Makanan', false),
                          _buildCategoryChip('🥤 Minuman', false),
                          _buildCategoryChip('🍞 Cemilan', false),
                        ],
                      ),
                    ),
                    // Product Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: 6,
                        itemBuilder: (context, index) =>
                            _buildProductCard(index),
                      ),
                    ),
                  ],
                ),
              ),

              // Cart Sidebar
              Container(
                width: MediaQuery.of(context).size.width * 0.38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(color: AppTheme.dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_cart_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Keranjang',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 40,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keranjang kosong',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Total & Pay Button
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBg,
                        border: Border(
                          top: BorderSide(color: AppTheme.dividerColor),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Rp 0',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.payment_rounded, size: 20),
                              label: Text(
                                'BAYAR',
                                style: GoogleFonts.inter(
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
        selected: isActive,
        onSelected: (_) {},
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.12),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(
          color: isActive ? AppTheme.primaryColor : AppTheme.borderColor,
        ),
      ),
    );
  }

  Widget _buildProductCard(int index) {
    final products = [
      {'emoji': '🍜', 'name': 'Indomie Goreng', 'price': 'Rp 3.500'},
      {'emoji': '☕', 'name': 'Kopi Mix', 'price': 'Rp 5.000'},
      {'emoji': '🥤', 'name': 'Teh Pucuk', 'price': 'Rp 4.000'},
      {'emoji': '🍞', 'name': 'Roti Tawar', 'price': 'Rp 8.000'},
      {'emoji': '🧃', 'name': 'Aqua 600ml', 'price': 'Rp 3.000'},
      {'emoji': '🍫', 'name': 'Taro Net', 'price': 'Rp 2.500'},
    ];

    final p = products[index];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p['emoji']!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              p['name']!,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              p['price']!,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== INVENTORY TAB (Placeholder) =====
  Widget _buildInventoryTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('📦 Inventaris Produk')),
      body: const Center(child: Text('Inventaris - Coming Soon')),
    );
  }

  // ===== SETTINGS TAB (Placeholder) =====
  Widget _buildSettingsTab() {
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Pengaturan Toko')),
      body: const Center(child: Text('Settings - Coming Soon')),
    );
  }
}
