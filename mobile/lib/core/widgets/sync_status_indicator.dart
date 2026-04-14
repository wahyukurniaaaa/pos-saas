import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/services/sync_service.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';

import 'package:posify_app/core/providers/license_tier_provider.dart';

/// A compact widget that displays the current cloud sync status.
/// Only visible for Pro users (authenticated via Supabase + Pro Tier).
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isProAsync = ref.watch(isProUserProvider);

    // Hidden for non-authenticated or non-Pro users
    return isProAsync.when(
      data: (isPro) {
        if (user == null || !isPro) return const SizedBox.shrink();

        final status = ref.watch(syncStatusProvider);
        return _buildBody(ref, status);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildBody(WidgetRef ref, SyncStatus status) {
    return GestureDetector(
      onTap: () => ref.read(syncServiceProvider).performSync(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _bgColor(status).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _bgColor(status).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(status),
            const SizedBox(width: 5),
            Text(
              _label(status),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _bgColor(status),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncStatus status) {
    if (status == SyncStatus.syncing) {
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: _bgColor(status),
        ),
      );
    }
    return Icon(_icon(status), size: 13, color: _bgColor(status));
  }

  Color _bgColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return AppTheme.infoColor;
      case SyncStatus.error:
        return AppTheme.errorColor;
      case SyncStatus.idle:
        return AppTheme.successColor;
    }
  }

  IconData _icon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return Icons.cloud_sync_rounded;
      case SyncStatus.error:
        return Icons.cloud_off_rounded;
      case SyncStatus.idle:
        return Icons.cloud_done_rounded;
    }
  }

  String _label(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Menyinkron...';
      case SyncStatus.error:
        return 'Gagal Sinkron';
      case SyncStatus.idle:
        return 'Tersinkron';
    }
  }
}
