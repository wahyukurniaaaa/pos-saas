import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget yang menampilkan indikator progres multi-langkah untuk alur registrasi.
///
/// Menampilkan [totalSteps] langkah yang dihubungkan dengan garis horizontal.
/// Setiap langkah memiliki visual berbeda berdasarkan statusnya:
/// - Langkah selesai (< [currentStep]): filled circle + ikon centang, warna primary
/// - Langkah aktif (== [currentStep]): filled circle + nomor, warna primary
/// - Langkah belum dikunjungi (> [currentStep]): outlined circle + nomor, warna abu
///
/// [currentStep] adalah 0-indexed.
class StepIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  }) : assert(totalSteps > 0, 'totalSteps harus lebih dari 0'),
       assert(currentStep >= 0 && currentStep < totalSteps,
           'currentStep harus antara 0 dan totalSteps - 1');

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    const greyColor = Color(0xFFCBD5E1); // slate-300

    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        // Indeks genap = step circle, indeks ganjil = garis penghubung
        if (index.isOdd) {
          // Garis penghubung antara step (index / 2) dan (index / 2 + 1)
          final leftStepIndex = index ~/ 2;
          final isCompleted = leftStepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted ? primaryColor : greyColor,
            ),
          );
        } else {
          final stepIndex = index ~/ 2;
          return _buildStepCircle(
            context: context,
            stepIndex: stepIndex,
            primaryColor: primaryColor,
            greyColor: greyColor,
          );
        }
      }),
    );
  }

  Widget _buildStepCircle({
    required BuildContext context,
    required int stepIndex,
    required Color primaryColor,
    required Color greyColor,
  }) {
    final isCompleted = stepIndex < currentStep;
    final isActive = stepIndex == currentStep;
    final stepNumber = stepIndex + 1;

    const double circleSize = 32.0;

    if (isCompleted) {
      // Langkah selesai: filled circle + ikon centang
      return Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 18,
        ),
      );
    } else if (isActive) {
      // Langkah aktif: filled circle + nomor, warna primary
      return Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$stepNumber',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      // Langkah belum dikunjungi: outlined circle + nomor, warna abu
      return Container(
        width: circleSize,
        height: circleSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: greyColor, width: 2),
        ),
        child: Center(
          child: Text(
            '$stepNumber',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: greyColor,
            ),
          ),
        ),
      );
    }
  }
}
