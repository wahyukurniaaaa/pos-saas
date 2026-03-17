import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../../features/pos/providers/pos_providers.dart';

class ProductImage extends ConsumerWidget {
  final String? imageUri;
  final String? productName;
  final int? categoryId;
  final double? width;
  final double? height;
  final double borderRadius;
  final double iconSize;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.imageUri,
    this.productName,
    this.categoryId,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.iconSize = 24,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get keywords from product name first (highest precision)
    String? matchedName = productName?.toLowerCase();

    // 2. If no match from name, fallback to category name
    if (matchedName == null || _isGeneric(matchedName)) {
      final categoriesAsync = ref.watch(categoryProvider);
      if (categoryId != null && categoriesAsync.value != null) {
        try {
          final category = categoriesAsync.value!.firstWhere(
            (c) => c.id == categoryId,
          );
          matchedName = category.name.toLowerCase();
        } catch (_) {}
      }
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: imageUri != null && imageUri!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image(
                image: imageUri!.startsWith('http')
                    ? NetworkImage(imageUri!) as ImageProvider
                    : FileImage(File(imageUri!)),
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) =>
                    _buildImagePlaceholder(matchedName, iconSize),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: iconSize * 0.8,
                      height: iconSize * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                },
              ),
            )
          : _buildImagePlaceholder(matchedName, iconSize),
    );
  }

  bool _isGeneric(String name) {
    // If name is too short or doesn't match any of our sector keywords, 
    // we consider it generic and try category fallback
    return getCategoryIcon(name) == Icons.inventory_2_rounded;
  }

  static IconData getCategoryIcon(String? name) {
    if (name == null || name.isEmpty)
      return Icons.inventory_2_rounded; // Default box icon

    final n = name.toLowerCase();

    // 1. Minuman & Kafe (Drinks & Cafe)
    if (n.contains('minum') ||
        n.contains('kopi') ||
        n.contains('teh') ||
        n.contains('drink') ||
        n.contains('air') ||
        n.contains('jus') ||
        n.contains('sirup') ||
        n.contains('susu') ||
        n.contains('boba') ||
        n.contains('es ') ||
        n.contains('ice')) {
      return Icons.local_cafe_rounded;
    }

    // 2. Makanan Berat & Warung Makan (Food & Catering)
    if (n.contains('makan') ||
        n.contains('food') ||
        n.contains('nasi') ||
        n.contains('mie') ||
        n.contains('bakso') ||
        n.contains('soto') ||
        n.contains('ayam') ||
        n.contains('ikan') ||
        n.contains('daging') ||
        n.contains('lauk') ||
        n.contains('sayur') ||
        n.contains('sate') ||
        n.contains('gorengan') ||
        n.contains('bakmi') ||
        n.contains('resto')) {
      return Icons.restaurant_rounded;
    }

    // 3. Sembako & Kebutuhan Dapur (Groceries & Basic Needs)
    if (n.contains('sembako') ||
        n.contains('beras') ||
        n.contains('gula') ||
        n.contains('minyak') ||
        n.contains('telur') ||
        n.contains('tepung') ||
        n.contains('kebutuhan') ||
        n.contains('bumbu') ||
        n.contains('kecap') ||
        n.contains('garam') ||
        n.contains('sembilan bahan')) {
      return Icons.shopping_basket_rounded;
    }

    // 4. Camilan & Roti (Snacks & Bakery)
    if (n.contains('camilan') ||
        n.contains('snack') ||
        n.contains('kue') ||
        n.contains('roti') ||
        n.contains('biskuit') ||
        n.contains('keripik') ||
        n.contains('cokelat') ||
        n.contains('dessert') ||
        n.contains('jajanan') ||
        n.contains('tahu') ||
        n.contains('tempe') ||
        n.contains('cilok') ||
        n.contains('seblak') ||
        n.contains('pempek') ||
        n.contains('batagor') ||
        n.contains('siomay') ||
        n.contains('gejrot')) {
      return Icons.cookie_rounded;
    }

    // 5. Toko Bangunan & Material (Hardware & Building Materials)
    if (n.contains('bangun') ||
        n.contains('material') ||
        n.contains('besi') ||
        n.contains('cat') ||
        n.contains('paku') ||
        n.contains('alat') ||
        n.contains('kayu') ||
        n.contains('semen') ||
        n.contains('pipa') ||
        n.contains('kabel') ||
        n.contains('keramik') ||
        n.contains('kuas')) {
      return Icons.handyman_rounded;
    }

    // 6. Fashion & Pakaian (Clothing & Apparel)
    if (n.contains('pakaian') ||
        n.contains('baju') ||
        n.contains('celana') ||
        n.contains('sepatu') ||
        n.contains('fashion') ||
        n.contains('kaos') ||
        n.contains('kemeja') ||
        n.contains('jaket') ||
        n.contains('topi') ||
        n.contains('tas') ||
        n.contains('hijab') ||
        n.contains('gamis')) {
      return Icons.checkroom_rounded;
    }

    // 7. Obat, Apotek & Kesehatan (Pharmacy & Health)
    if (n.contains('obat') ||
        n.contains('kesehatan') ||
        n.contains('vitamin') ||
        n.contains('farmasi') ||
        n.contains('medis') ||
        n.contains('pil') ||
        n.contains('herbal') ||
        n.contains('apotek')) {
      return Icons.medical_services_rounded;
    }

    // 8. Elektronik & HP (Electronics & Gadgets)
    if (n.contains('elektronik') ||
        n.contains('hp') ||
        n.contains('handphone') ||
        n.contains('gadget') ||
        n.contains('komputer') ||
        n.contains('laptop') ||
        n.contains('aksesoris') ||
        n.contains('charger') ||
        n.contains('kamera') ||
        n.contains('pulsa') ||
        n.contains('kuota')) {
      return Icons.devices_rounded;
    }

    // 9. Skincare, Kosmetik & Perawatan (Beauty & Cosmetics)
    if (n.contains('kosmetik') ||
        n.contains('skincare') ||
        n.contains('kecantikan') ||
        n.contains('makeup') ||
        n.contains('sabun') ||
        n.contains('shampo') ||
        n.contains('parfum') ||
        n.contains('perawatan') ||
        n.contains('body care')) {
      return Icons.face_retouching_natural_rounded;
    }

    // 10. Otomotif & Bengkel (Automotive & Garage)
    if (n.contains('otomotif') ||
        n.contains('bengkel') ||
        n.contains('motor') ||
        n.contains('mobil') ||
        n.contains('oli') ||
        n.contains('ban') ||
        n.contains('sparepart') ||
        n.contains('suku cadang') ||
        n.contains('helm')) {
      return Icons.build_circle_rounded;
    }

    // 11. Alat Tulis & Fotokopi (Stationery & Office)
    if (n.contains('atk') ||
        n.contains('tulis') ||
        n.contains('buku') ||
        n.contains('kertas') ||
        n.contains('pensil') ||
        n.contains('pulpen') ||
        n.contains('fotokopi') ||
        n.contains('kantor') ||
        n.contains('print')) {
      return Icons.edit_note_rounded;
    }

    // 12. Jasa & Layanan (Services - e.g. Salon, Laundry)
    if (n.contains('jasa') ||
        n.contains('layanan') ||
        n.contains('service') ||
        n.contains('laundry') ||
        n.contains('cucian') ||
        n.contains('salon') ||
        n.contains('cukur') ||
        n.contains('pijat')) {
      return Icons.cleaning_services_rounded;
    }

    // 13. Pertanian & Peternakan (Agriculture & Farming)
    if (n.contains('tani') ||
        n.contains('pupuk') ||
        n.contains('bibit') ||
        n.contains('pakan') ||
        n.contains('ternak') ||
        n.contains('hewan') ||
        n.contains('burung') ||
        n.contains('ikan')) {
      return Icons.pets_rounded;
    }

    // Generic fallback for unknown categories
    return Icons.inventory_2_rounded;
  }

  Widget _buildImagePlaceholder(String? categoryName, double size) {
    return Center(
      child: Icon(
        getCategoryIcon(categoryName),
        color: AppTheme.tertiaryColor.withValues(alpha: 0.5),
        size: size,
      ),
    );
  }
}
