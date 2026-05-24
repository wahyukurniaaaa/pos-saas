import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumio/features/auth/models/subscription_package.dart';

/// Widget kartu yang menampilkan detail satu paket berlangganan.
///
/// Menampilkan nama paket, harga terformat, durasi, dan daftar fitur.
/// Memberikan visual feedback saat [isSelected] = true:
/// - Border berwarna primary dengan lebar 2
/// - Background sedikit lebih terang (primary dengan opacity rendah)
class PackageCardWidget extends StatelessWidget {
  final SubscriptionPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const PackageCardWidget({
    super.key,
    required this.package,
    required this.isSelected,
    required this.onTap,
  });

  /// Mengembalikan label durasi yang sesuai.
  /// Jika [durationMonths] == 0, tampilkan "Seumur Hidup".
  /// Jika > 0, tampilkan "${durationMonths} Bulan".
  String get _durationLabel {
    if (package.durationMonths == 0) return 'Seumur Hidup';
    return '${package.durationMonths} Bulan';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final selectedBgColor = primaryColor.withValues(alpha: 0.06);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: nama paket + badge terpilih
            Row(
              children: [
                Expanded(
                  child: Text(
                    package.name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? primaryColor
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Dipilih',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Harga
            Text(
              package.formattedPrice,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isSelected ? primaryColor : const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),

            // Durasi
            Row(
              children: [
                Icon(
                  package.durationMonths == 0
                      ? Icons.all_inclusive_rounded
                      : Icons.calendar_month_outlined,
                  size: 14,
                  color: const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  _durationLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            if (package.features.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Daftar fitur
              ...package.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.12)
                              : const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: isSelected
                              ? primaryColor
                              : const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
