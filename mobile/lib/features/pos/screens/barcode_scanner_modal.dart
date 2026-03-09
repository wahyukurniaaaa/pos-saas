import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import '../providers/pos_providers.dart';

class BarcodeScannerModal extends ConsumerStatefulWidget {
  final bool returnResult;
  const BarcodeScannerModal({super.key, this.returnResult = false});

  @override
  ConsumerState<BarcodeScannerModal> createState() =>
      _BarcodeScannerModalState();

  static Future<String?> show(
    BuildContext context, {
    bool returnResult = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BarcodeScannerModal(returnResult: returnResult),
    );
  }
}

class _BarcodeScannerModalState extends ConsumerState<BarcodeScannerModal> {
  final MobileScannerController controller = MobileScannerController();
  String? _lastScanned;
  DateTime? _lastScannedTime;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String code) async {
    final now = DateTime.now();
    // Prevent double scans of the same item within 1.5 seconds
    if (_lastScanned == code &&
        _lastScannedTime != null &&
        now.difference(_lastScannedTime!) <
            const Duration(milliseconds: 1500)) {
      return;
    }

    _lastScanned = code;
    _lastScannedTime = now;

    if (widget.returnResult) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, code);
      return;
    }

    final db = ref.read(databaseProvider);
    final product = await db.getProductBySku(code);

    if (!mounted) return;

    if (product != null) {
      ref.read(cartProvider.notifier).addToCart(product);
      HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil menambah: ${product.name}'),
          backgroundColor: AppTheme.successColor,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk dengan SKU $code tidak ditemukan'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Scan Barcode / SKU',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scanner Area
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      final String? code = barcode.rawValue;
                      if (code != null) {
                        _processBarcode(code);
                      }
                    }
                  },
                ),

                // Overlay UI
                Center(
                  child: Container(
                    width: 250,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        'Arahkan kamera ke barcode produk',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => controller.toggleTorch(),
                  icon: ValueListenableBuilder(
                    valueListenable: controller,
                    builder: (context, state, child) {
                      final torchState = state.torchState;
                      switch (torchState) {
                        case TorchState.on:
                          return const Icon(Icons.flash_on_rounded);
                        default:
                          return const Icon(Icons.flash_off_rounded);
                      }
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => controller.switchCamera(),
                  icon: const Icon(Icons.cameraswitch_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
