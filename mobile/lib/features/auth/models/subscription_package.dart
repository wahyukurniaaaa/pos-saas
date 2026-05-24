import 'package:intl/intl.dart';

/// Model untuk paket berlangganan yang diambil dari tabel `subscription_packages`
/// di Supabase, atau dari daftar fallback hardcoded jika fetch gagal.
class SubscriptionPackage {
  final String name;
  final String slug;

  /// Harga dalam Rupiah (integer)
  final int price;

  /// Durasi dalam bulan. 0 berarti lifetime (seumur hidup).
  final int durationMonths;

  /// Daftar fitur yang disertakan dalam paket ini.
  final List<String> features;

  const SubscriptionPackage({
    required this.name,
    required this.slug,
    required this.price,
    required this.durationMonths,
    required this.features,
  });

  /// Parsing dari JSON response Supabase (`subscription_packages` table).
  ///
  /// Field mapping:
  /// - `name` → name
  /// - `slug` → slug
  /// - `price` → price
  /// - `duration_months` → durationMonths
  /// - `features` (JSONB, comes as `List<dynamic>`) → features
  factory SubscriptionPackage.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final List<String> features;
    if (rawFeatures is List) {
      features = rawFeatures.map((e) => e.toString()).toList();
    } else {
      features = [];
    }

    return SubscriptionPackage(
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: json['price'] as int,
      durationMonths: json['duration_months'] as int,
      features: features,
    );
  }

  /// Harga terformat dalam Rupiah menggunakan locale `id_ID`.
  ///
  /// Contoh: 249000 → "Rp 249.000"
  String get formattedPrice => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);

  /// Daftar paket fallback hardcoded yang ditampilkan jika fetch dari Supabase
  /// gagal atau timeout.
  static List<SubscriptionPackage> get fallbackPackages => [
        const SubscriptionPackage(
          name: 'Lite',
          slug: 'lite',
          price: 99000,
          durationMonths: 0,
          features: [
            'Maks. 1 Outlet',
            'Maks. 1 Perangkat',
            'Laporan Standar',
          ],
        ),
        const SubscriptionPackage(
          name: 'Pro',
          slug: 'pro',
          price: 249000,
          durationMonths: 1,
          features: [
            'Multi-Outlet',
            'Multi-Perangkat',
            'Cloud Sync',
            'Analytics Pro',
          ],
        ),
      ];
}
