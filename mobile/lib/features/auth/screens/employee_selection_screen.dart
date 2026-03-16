import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'pin_login_screen.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class EmployeeSelectionScreen extends ConsumerWidget {
  const EmployeeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: ResponsiveCenter(
            maxWidth: 600,
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'POSify',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih Profil Anda',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),

                // Employee Grid
                Expanded(
                  child: StreamBuilder<List<Employee>>(
                    stream: db.watchAllEmployees(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final employees = snapshot.data ?? [];

                      if (employees.isEmpty) {
                        return const Center(child: Text('Tidak ada karyawan.'));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: employees.length,
                        itemBuilder: (context, index) {
                          final employee = employees[index];
                          return _EmployeeCard(employee: employee);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PinLoginScreen(employee: employee),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                image: employee.photoUri != null
                    ? DecorationImage(
                        image: FileImage(File(employee.photoUri!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: employee.photoUri == null
                  ? Center(
                      child: Text(
                        employee.name.substring(0, 1).toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              employee.name,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(employee.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getRoleLabel(employee.role),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(employee.role),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'OWNER';
      case 'supervisor':
        return 'SPV';
      case 'cashier':
        return 'KASIR';
      default:
        return role.toUpperCase();
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return AppTheme.primaryColor;
      case 'supervisor':
        return Colors.orange;
      case 'cashier':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }
}
