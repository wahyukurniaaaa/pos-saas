import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

// Provider that fetches customer loyalty leaderboard
final loyaltyLeaderboardProvider =
    FutureProvider<List<CustomerLoyaltyStat>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getLoyaltyLeaderboard();
});

class LoyaltyAnalyticsScreen extends ConsumerStatefulWidget {
  const LoyaltyAnalyticsScreen({super.key});

  @override
  ConsumerState<LoyaltyAnalyticsScreen> createState() =>
      _LoyaltyAnalyticsScreenState();
}

class _LoyaltyAnalyticsScreenState
    extends ConsumerState<LoyaltyAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(loyaltyLeaderboardProvider);
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Loyalty Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Poin Tertinggi'),
            Tab(text: 'Paling Aktif'),
          ],
        ),
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats.isEmpty) {
            return _buildEmptyState();
          }

          final byPoints = [...stats]
            ..sort((a, b) => b.customer.points.compareTo(a.customer.points));

          final byActivity = [...stats]
            ..sort(
                (a, b) => b.transactionCount.compareTo(a.transactionCount));

          return ResponsiveCenter(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboard(byPoints, currency, 'poin'),
                _buildLeaderboard(byActivity, currency, 'transaksi'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stars_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada data member',
            style: GoogleFonts.poppins(
                fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Data akan muncul setelah ada transaksi dengan member.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(
    List<CustomerLoyaltyStat> stats,
    NumberFormat currency,
    String sortBy,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 40),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final rank = index + 1;
        return _buildRankCard(stat, rank, currency, sortBy);
      },
    );
  }

  Widget _buildRankCard(
    CustomerLoyaltyStat stat,
    int rank,
    NumberFormat currency,
    String sortBy,
  ) {
    final isTop3 = rank <= 3;

    final medalColors = {
      1: const Color(0xFFFFD700), // Gold
      2: const Color(0xFFC0C0C0), // Silver
      3: const Color(0xFFCD7F32), // Bronze
    };

    final medalColor = medalColors[rank] ?? AppTheme.primaryColor.withValues(alpha: 0.15);
    final medalTextColor = rank <= 3 ? Colors.white : AppTheme.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isTop3
            ? Border.all(color: medalColors[rank]!.withValues(alpha: 0.5), width: 2)
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: isTop3
                ? medalColors[rank]!.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isTop3 ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isTop3 ? medalColor : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: rank <= 3
                    ? Icon(
                        Icons.emoji_events_rounded,
                        size: 22,
                        color: medalTextColor,
                      )
                    : Text(
                        '$rank',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),

            // Avatar
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              radius: 22,
              child: Text(
                stat.customer.name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.customer.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (stat.customer.phone != null &&
                      stat.customer.phone!.isNotEmpty)
                    Text(
                      stat.customer.phone!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatChip(
                        '${stat.transactionCount}x',
                        Icons.receipt_rounded,
                        AppTheme.infoColor,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        currency.format(stat.totalSpend),
                        Icons.payments_rounded,
                        AppTheme.successColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars_rounded,
                      color: Colors.amber.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stat.customer.points}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                Text(
                  'poin',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
