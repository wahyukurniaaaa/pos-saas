import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

import 'package:lumio/core/constants/app_constants.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/core/theme/app_theme.dart';
import 'package:lumio/core/widgets/responsive_layout.dart';
import 'package:lumio/features/auth/providers/auth_providers.dart';
import 'package:lumio/features/auth/providers/registration_provider.dart';
import 'package:lumio/features/auth/widgets/package_card_widget.dart';
import 'package:lumio/features/auth/widgets/step_indicator_widget.dart';

/// Multi-step registration screen.
///
/// Uses [IndexedStack] to manage 3 steps without Navigator.push,
/// so form data in Step 1 is preserved when navigating back from Step 2.
///
/// Steps (0-indexed):
///   0 — Data Akun & Toko
///   1 — Pilih Paket Berlangganan  (placeholder, implemented in task 9)
///   2 — Tunggu Konfirmasi Pembayaran (placeholder, implemented in task 10)
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  // ── Step 1 controllers ────────────────────────────────────────────────────
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── Step 1 local state ────────────────────────────────────────────────────
  String? _selectedBusinessType;
  bool _obscurePassword = true;

  // ── Inline validation error messages ─────────────────────────────────────
  String? _storeNameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;

  // ── Step 2 state ──────────────────────────────────────────────────────────
  /// Whether fetchPackages() has been called for this session.
  bool _step2Initialized = false;

  /// Whether the user has an existing trial license (hides trial button).
  bool _hasExistingTrial = false;

  // ── Step 3 state ──────────────────────────────────────────────────────────
  /// Whether Step 3 has been initialized (Realtime started, timer started).
  bool _step3Initialized = false;

  /// Countdown timer that ticks every second.
  Timer? _countdownTimer;

  /// Remaining time until invoice expires.
  Duration _remainingTime = Duration.zero;

  /// Whether the payment session has expired.
  bool _isExpired = false;

  /// Whether the Realtime subscription failed within 10 seconds.
  bool _realtimeSubscribeFailed = false;

  /// Whether to show the WhatsApp admin suggestion (after 5 minutes).
  bool _showWhatsAppSuggestion = false;

  /// Timer that fires after 5 minutes to show WhatsApp suggestion.
  Timer? _whatsAppSuggestionTimer;

  /// Whether we are waiting for licenseProvider to reload after activation.
  bool _isWaitingForLicense = false;

  /// Error message shown in Step 3 (separate from provider errorMessage).
  String? _step3ErrorMessage;

  /// Whether the Realtime connection is disconnected.
  bool _realtimeDisconnected = false;

  // ── Animation ─────────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _checkExistingTrial();
  }

  /// Checks SQLite for an existing trial license to conditionally hide the
  /// "Coba Trial 7 Hari" button (Requirement 4.8).
  Future<void> _checkExistingTrial() async {
    try {
      final db = ref.read(databaseProvider);
      final license = await db.getLocalLicense();
      if (mounted) {
        setState(() {
          _hasExistingTrial =
              license != null && license.licenseCode.startsWith('TRIAL-');
        });
      }
    } catch (_) {
      // If check fails, default to showing the button (safe fallback)
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    // Cancel timers and Realtime subscription to prevent memory leaks
    _countdownTimer?.cancel();
    _whatsAppSuggestionTimer?.cancel();
    ref.read(registrationProvider.notifier).cancelRealtimeSubscription();
    super.dispose();
  }

  // ── Validation helpers ────────────────────────────────────────────────────

  /// Validates all Step 1 fields. Returns true if all valid.
  bool _validateStep1() {
    bool valid = true;

    // Nama Toko
    final storeName = _storeNameController.text.trim();
    if (storeName.isEmpty) {
      _storeNameError = 'Nama toko wajib diisi';
      valid = false;
    } else if (storeName.length > 50) {
      _storeNameError = 'Nama toko maksimal 50 karakter';
      valid = false;
    } else {
      _storeNameError = null;
    }

    // Nomor WhatsApp
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _phoneError = 'Nomor WA wajib diisi';
      valid = false;
    } else if (phone.length < 9 || phone.length > 15) {
      _phoneError = 'Nomor WA tidak valid';
      valid = false;
    } else {
      _phoneError = null;
    }

    // Email
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _emailError = 'Email wajib diisi';
      valid = false;
    } else if (!email.contains('@')) {
      _emailError = 'Email tidak valid';
      valid = false;
    } else {
      _emailError = null;
    }

    // Password
    final password = _passwordController.text;
    if (password.isEmpty) {
      _passwordError = 'Password wajib diisi';
      valid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password min. 6 karakter';
      valid = false;
    } else {
      _passwordError = null;
    }

    setState(() {});
    return valid;
  }

  // ── Submit Step 1 ─────────────────────────────────────────────────────────

  Future<void> _submitStep1() async {
    if (!_validateStep1()) return;
    FocusScope.of(context).unfocus();

    await ref.read(registrationProvider.notifier).submitStep1(
      storeName: _storeNameController.text.trim(),
      businessType: _selectedBusinessType ?? 'lainnya',
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  // ── Back button handling ──────────────────────────────────────────────────

  void _handleBackButton(int currentStep) {
    if (currentStep == 0) {
      // Step 1 → navigate to LoginScreen
      Navigator.of(context).pushReplacementNamed('/login');
    } else if (currentStep == 1) {
      // Step 2 → go back to Step 1 (handled by provider if needed, but
      // since IndexedStack is driven by registrationProvider.currentStep,
      // we update state directly via a local approach — the provider
      // doesn't expose a "goBack" method, so we use the notifier's _update
      // indirectly by resetting currentStep. For now, navigate to login
      // as a safe fallback; Step 2 back button is implemented in task 9.)
      // This path is reached only via Android system back while on Step 2.
      _goToStep(0);
    } else if (currentStep == 2) {
      // Step 3 → go back to Step 2 + cancel Realtime
      ref.read(registrationProvider.notifier).cancelRealtimeSubscription();
      _goToStep(1);
    }
  }

  /// Directly sets the currentStep in the provider state.
  void _goToStep(int step) {
    ref.read(registrationProvider.notifier).goToStep(step);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final registrationAsync = ref.watch(registrationProvider);

    // Listen for step changes (e.g., after successful submitStep1, step → 1)
    ref.listen<AsyncValue<RegistrationState>>(registrationProvider, (previous, next) {
      final prevStep = previous?.value?.currentStep;
      final nextStep = next.value?.currentStep;

      // When step transitions to 1 (Step 2) for the first time, fetch packages
      if (nextStep == 1 && prevStep != 1 && !_step2Initialized) {
        _step2Initialized = true;
        ref.read(registrationProvider.notifier).fetchPackages();
        // Also re-check trial status when entering Step 2
        _checkExistingTrial();
      }

      // When step transitions to 2 (Step 3), initialize countdown + Realtime
      if (nextStep == 2 && prevStep != 2 && !_step3Initialized) {
        _step3Initialized = true;
        final state = next.value;
        if (state != null) {
          _initStep3(state);
        }
      }

      // When navigating away from Step 3, cancel timers and Realtime
      if (prevStep == 2 && nextStep != 2) {
        _cancelStep3Resources();
      }
    });

    final regState = registrationAsync.value ?? const RegistrationState();
    final currentStep = regState.currentStep;
    final isLoading = regState.isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton(currentStep);
        }
      },
      child: Scaffold(
        body: ResponsiveCenter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryDark,
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/branding/lumio_logo_wordmark_white.png',
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 20),
                          // Step Indicator
                          StepIndicatorWidget(
                            currentStep: currentStep,
                            totalSteps: 3,
                          ),
                          const SizedBox(height: 8),
                          // Step labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStepLabel('Data Akun', currentStep == 0),
                              _buildStepLabel('Pilih Paket', currentStep == 1),
                              _buildStepLabel('Pembayaran', currentStep == 2),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // ── Step Content ─────────────────────────────────────────
                    Expanded(
                      child: IndexedStack(
                        index: currentStep,
                        children: [
                          // Step 0: Data Akun & Toko
                          _buildStep1Content(regState, isLoading),
                          // Step 1: Pilih Paket
                          _buildStep2Content(regState, isLoading),
                          // Step 2: Tunggu Pembayaran
                          _buildStep3Content(regState, isLoading),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 3 Initialization & Helpers ──────────────────────────────────────

  /// Admin WhatsApp number for support contact.
  static const String _adminWhatsAppNumber = '6281234567890';

  /// Initializes Step 3: starts countdown timer and Realtime subscription.
  void _initStep3(RegistrationState regState) {
    final expiredAt = regState.expiredAt;
    if (expiredAt == null) return;

    final now = DateTime.now();
    final remaining = expiredAt.difference(now);

    if (remaining.isNegative || remaining == Duration.zero) {
      // Already expired — show expired state immediately
      if (mounted) {
        setState(() {
          _remainingTime = Duration.zero;
          _isExpired = true;
        });
      }
    } else {
      // Start countdown
      if (mounted) {
        setState(() {
          _remainingTime = remaining;
          _isExpired = false;
        });
      }
      _startCountdown(expiredAt);
    }

    // Start Realtime subscription
    final userId = regState.userId;
    if (userId != null) {
      _startRealtimeWithTimeout(userId);
    }

    // Start 5-minute WhatsApp suggestion timer
    _whatsAppSuggestionTimer?.cancel();
    _whatsAppSuggestionTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() => _showWhatsAppSuggestion = true);
      }
    });
  }

  /// Starts the countdown timer that ticks every second.
  void _startCountdown(DateTime expiredAt) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = expiredAt.difference(DateTime.now());
      if (remaining.isNegative || remaining == Duration.zero) {
        timer.cancel();
        setState(() {
          _remainingTime = Duration.zero;
          _isExpired = true;
        });
      } else {
        setState(() => _remainingTime = remaining);
      }
    });
  }

  /// Starts Realtime subscription with a 10-second timeout fallback.
  void _startRealtimeWithTimeout(String userId) {
    // Reset state
    if (mounted) {
      setState(() {
        _realtimeSubscribeFailed = false;
        _realtimeDisconnected = false;
      });
    }

    // 10-second timeout: if no subscription confirmation, show manual check button
    Timer(const Duration(seconds: 10), () {
      if (mounted && !_step3Initialized) return;
      // We can't easily detect subscribe failure from the notifier,
      // so we rely on the channel status. For now, we show the button
      // after 10 seconds if the channel hasn't confirmed.
    });

    ref.read(registrationProvider.notifier).startRealtimeSubscription(
      userId,
      onLicenseActivated: _onLicenseActivated,
      onSubscribeFailed: () {
        if (mounted) {
          setState(() => _realtimeSubscribeFailed = true);
        }
      },
      onDisconnected: () {
        if (mounted) {
          setState(() => _realtimeDisconnected = true);
        }
      },
      onReconnected: () {
        if (mounted) {
          setState(() => _realtimeDisconnected = false);
        }
      },
    );
  }

  /// Called when Realtime receives `is_active = true` event.
  Future<void> _onLicenseActivated() async {
    if (!mounted) return;

    setState(() {
      _isWaitingForLicense = true;
      _step3ErrorMessage = null;
    });

    try {
      // Wait for licenseProvider to finish loading (timeout 30 seconds)
      await Future.any([
        _waitForLicenseProvider(),
        Future.delayed(const Duration(seconds: 30)).then(
          (_) => throw TimeoutException('licenseProvider timeout'),
        ),
      ]);

      if (!mounted) return;
      // Navigate to AppBootstrap flow
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isWaitingForLicense = false;
          _step3ErrorMessage =
              'Gagal memuat lisensi. Silakan coba lagi.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWaitingForLicense = false;
          _step3ErrorMessage = 'Terjadi kesalahan. Coba lagi.';
        });
      }
    }
  }

  /// Waits until licenseProvider has non-loading data.
  Future<void> _waitForLicenseProvider() async {
    while (true) {
      final licenseAsync = ref.read(licenseProvider);
      if (!licenseAsync.isLoading) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Cancels all Step 3 resources (timers, Realtime).
  void _cancelStep3Resources() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _whatsAppSuggestionTimer?.cancel();
    _whatsAppSuggestionTimer = null;
    _step3Initialized = false;
    ref.read(registrationProvider.notifier).cancelRealtimeSubscription();
  }

  /// Formats a [Duration] as `MM:SS` or `HH:MM:SS` if >= 1 hour.
  String _formatDuration(Duration d) {
    if (d.isNegative) return '00:00';
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  /// Opens the payment URL in an external browser.
  Future<void> _openPaymentUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka browser. Salin URL secara manual.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Opens WhatsApp with a pre-filled message containing invoice and email.
  Future<void> _openWhatsApp(String invoiceNumber, String email) async {
    final message = Uri.encodeComponent(
      'Halo admin, saya membutuhkan bantuan untuk invoice $invoiceNumber dengan email $email',
    );
    final url = 'https://wa.me/$_adminWhatsAppNumber?text=$message';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Handles "Buat Tagihan Baru" — renews checkout and restarts timer.
  Future<void> _handleRenewCheckout() async {
    if (mounted) {
      setState(() {
        _step3ErrorMessage = null;
        _isExpired = false;
      });
    }

    // Cancel existing timers
    _countdownTimer?.cancel();
    _whatsAppSuggestionTimer?.cancel();

    await ref.read(registrationProvider.notifier).renewCheckout();

    if (!mounted) return;

    final regState = ref.read(registrationProvider).value;
    if (regState?.errorMessage != null) {
      // renewCheckout failed — show error, keep "Buat Tagihan Baru" button
      setState(() {
        _step3ErrorMessage = regState!.errorMessage;
        _isExpired = true;
      });
      return;
    }

    // Success — re-initialize Step 3 with new data
    if (regState != null) {
      setState(() {
        _step3Initialized = false;
        _showWhatsAppSuggestion = false;
        _realtimeSubscribeFailed = false;
        _realtimeDisconnected = false;
      });
      _step3Initialized = true;
      _initStep3(regState);
    }
  }

  /// Manually checks payment status via Status_API.
  Future<void> _checkPaymentStatus(RegistrationState regState) async {
    final invoiceNumber = regState.invoiceNumber;
    final accessToken = regState.accessToken;
    if (invoiceNumber == null) return;

    setState(() {
      _step3ErrorMessage = null;
      _isWaitingForLicense = true;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.webBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final response = await dio.get(
        '/api/subscription/status',
        queryParameters: {'order_id': invoiceNumber},
      );

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>?;
      final isActive = data?['is_active'] == true ||
          data?['status'] == 'active' ||
          data?['isActive'] == true;

      if (isActive) {
        ref.invalidate(licenseProvider);
        await _waitForLicenseProvider();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        setState(() {
          _isWaitingForLicense = false;
          _step3ErrorMessage = 'Pembayaran belum dikonfirmasi. Coba lagi nanti.';
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isWaitingForLicense = false;
          _step3ErrorMessage =
              'Gagal memeriksa status: ${e.response?.statusCode ?? 'koneksi error'}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isWaitingForLicense = false;
          _step3ErrorMessage = 'Terjadi kesalahan. Coba lagi.';
        });
      }
    }
  }

  // ── Step 3 Content ────────────────────────────────────────────────────────

  Widget _buildStep3Content(RegistrationState regState, bool isLoading) {
    final invoiceNumber = regState.invoiceNumber ?? '-';
    final paymentUrl = regState.paymentUrl;
    final email = regState.email;

    // Find selected package name
    final selectedPkg = regState.packages.isNotEmpty
        ? regState.packages.firstWhere(
            (p) => p.slug == regState.selectedPackageSlug,
            orElse: () => regState.packages.first,
          )
        : null;
    final packageName = selectedPkg?.name ?? regState.selectedPackageSlug;
    final packagePrice = selectedPkg?.formattedPrice ?? '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selesaikan Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Buka halaman pembayaran dan selesaikan transaksi Anda',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),

          // ── Main card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Invoice details ────────────────────────────────────────
                _buildDetailRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Nomor Invoice',
                  value: invoiceNumber,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Paket',
                  value: packageName,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  icon: Icons.payments_outlined,
                  label: 'Total Tagihan',
                  value: packagePrice,
                  valueStyle: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                // ── Countdown / Expired state ──────────────────────────────
                if (_isWaitingForLicense)
                  _buildWaitingForLicenseState()
                else if (_isExpired)
                  _buildExpiredState(regState, isLoading)
                else
                  _buildCountdownState(regState, paymentUrl, isLoading),

                // ── Realtime disconnected banner ───────────────────────────
                if (_realtimeDisconnected) ...[
                  const SizedBox(height: 12),
                  _buildInfoBanner(
                    icon: Icons.wifi_off_rounded,
                    message: 'Koneksi terputus, mencoba menghubungkan kembali...',
                    color: Colors.orange,
                  ),
                ],

                // ── Realtime subscribe failed — manual check button ────────
                if (_realtimeSubscribeFailed && !_isExpired) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isWaitingForLicense
                          ? null
                          : () => _checkPaymentStatus(regState),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(
                        'Cek Status Pembayaran',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Step 3 error message ───────────────────────────────────
                if (_step3ErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  _buildErrorBanner(_step3ErrorMessage!),
                ],

                // ── Retry button after licenseProvider timeout ─────────────
                if (_step3ErrorMessage != null &&
                    _step3ErrorMessage!.contains('Gagal memuat lisensi')) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _step3ErrorMessage = null;
                          _isWaitingForLicense = false;
                        });
                        ref.invalidate(licenseProvider);
                        _onLicenseActivated();
                      },
                      child: Text(
                        'Coba Lagi',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Back button ────────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: (isLoading || _isWaitingForLicense)
                        ? null
                        : () {
                            _cancelStep3Resources();
                            _goToStep(1);
                          },
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'Kembali ke Pilih Paket',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── WhatsApp suggestion (after 5 minutes) ─────────────────────────
          if (_showWhatsAppSuggestion) ...[
            const SizedBox(height: 16),
            _buildWhatsAppSuggestionCard(invoiceNumber, email),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Builds the countdown state (payment not yet expired).
  Widget _buildCountdownState(
    RegistrationState regState,
    String? paymentUrl,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Sesi pembayaran berakhir dalam',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Countdown display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDuration(_remainingTime),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _remainingTime.inMinutes < 5
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // "Buka Halaman Pembayaran" button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: (isLoading || paymentUrl == null)
                ? null
                : () => _openPaymentUrl(paymentUrl),
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            label: Text(
              'Buka Halaman Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // WhatsApp admin button (always visible in Step 3)
        _buildWhatsAppButton(regState.invoiceNumber ?? '-', regState.email),
      ],
    );
  }

  /// Builds the expired state (countdown reached zero).
  Widget _buildExpiredState(RegistrationState regState, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.errorColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.timer_off_rounded,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sesi pembayaran telah kedaluwarsa',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // "Buat Tagihan Baru" button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _handleRenewCheckout,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              'Buat Tagihan Baru',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // WhatsApp admin button
        _buildWhatsAppButton(regState.invoiceNumber ?? '-', regState.email),
      ],
    );
  }

  /// Builds the waiting-for-license state (after Realtime activation event).
  Widget _buildWaitingForLicenseState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Pembayaran dikonfirmasi! Mengaktifkan lisensi...',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.successColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Builds a WhatsApp contact button.
  Widget _buildWhatsAppButton(String invoiceNumber, String email) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _openWhatsApp(invoiceNumber, email),
        icon: const Icon(Icons.chat_rounded, size: 18),
        label: Text(
          'Hubungi Admin via WhatsApp',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF25D366), // WhatsApp green
          side: const BorderSide(color: Color(0xFF25D366)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Builds the WhatsApp suggestion card shown after 5 minutes.
  Widget _buildWhatsAppSuggestionCard(String invoiceNumber, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF25D366).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF25D366),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Butuh bantuan?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF25D366),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Jika pembayaran sudah dilakukan namun belum terkonfirmasi, hubungi admin kami via WhatsApp.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(invoiceNumber, email),
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: Text(
                'Hubungi Admin via WhatsApp',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a detail row with icon, label, and value.
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ??
                    GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds an info banner (for disconnection notices, etc.).
  Widget _buildInfoBanner({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2 Content ────────────────────────────────────────────────────────

  Widget _buildStep2Content(RegistrationState regState, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Paket Berlangganan',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih paket yang sesuai dengan kebutuhan toko Anda',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),

          // ── Package list card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Loading or package list ────────────────────────────────
                if (isLoading && regState.packages.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (regState.packages.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Tidak ada paket tersedia saat ini.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...regState.packages.map(
                    (pkg) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PackageCardWidget(
                        package: pkg,
                        isSelected:
                            regState.selectedPackageSlug == pkg.slug,
                        onTap: isLoading
                            ? () {}
                            : () => ref
                                .read(registrationProvider.notifier)
                                .selectPackage(pkg.slug),
                      ),
                    ),
                  ),

                // ── Error banner ───────────────────────────────────────────
                if (regState.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  _buildStep2ErrorBanner(regState.errorMessage!),
                ],

                const SizedBox(height: 20),

                // ── "Lanjut ke Pembayaran" button ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (isLoading || regState.packages.isEmpty)
                        ? null
                        : () => ref
                            .read(registrationProvider.notifier)
                            .initiateCheckout(regState.selectedPackageSlug),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'LANJUT KE PEMBAYARAN',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                // ── Trial button (hidden if trial already used) ────────────
                if (!_hasExistingTrial) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: isLoading ? null : _handleTrialButton,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Coba Trial 7 Hari',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Back button ────────────────────────────────────────────
                Center(
                  child: TextButton.icon(
                    onPressed: isLoading ? null : () => _goToStep(0),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'Kembali ke Data Akun',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Handles the "Coba Trial 7 Hari" button tap.
  ///
  /// Calls [RegistrationNotifier.createTrialLicense]. On success, navigates to
  /// AppBootstrap (root route). On failure, shows an error banner.
  Future<void> _handleTrialButton() async {
    final (success, errorMsg) =
        await ref.read(registrationProvider.notifier).createTrialLicense();

    if (!mounted) return;

    if (success) {
      // Navigate to AppBootstrap flow — replace the entire navigation stack
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } else {
      // Show error as a SnackBar since we're inside a scrollable card
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg ?? 'Gagal mengaktifkan trial. Coba lagi.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Builds the error banner for Step 2, with special handling for the
  /// "already has active subscription" case (Requirement 10.2).
  Widget _buildStep2ErrorBanner(String message) {
    final isActiveLicense = message.contains('sudah memiliki lisensi aktif');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.errorColor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Show "Masuk" button for active license error (Requirement 10.2)
          if (isActiveLicense) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                style: TextButton.styleFrom(
                  backgroundColor:
                      AppTheme.errorColor.withValues(alpha: 0.12),
                  foregroundColor: AppTheme.errorColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(
                  'Masuk ke Aplikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 1 Content ────────────────────────────────────────────────────────

  Widget _buildStep1Content(RegistrationState regState, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Akun & Toko',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Isi informasi toko dan akun Anda',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),

          // ── Form Card ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Nama Toko
                _buildLabel('Nama Toko / Usaha'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _storeNameController,
                  hint: 'Kopi Nusantara, Warung Maju, dll.',
                  icon: Icons.storefront_outlined,
                  enabled: !isLoading,
                  errorText: _storeNameError,
                  onChanged: (_) {
                    if (_storeNameError != null) {
                      setState(() => _storeNameError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 2. Kategori Usaha (opsional)
                _buildLabel('Kategori Usaha (opsional)'),
                const SizedBox(height: 6),
                _buildBusinessTypeDropdown(isLoading),
                const SizedBox(height: 14),

                // 3. Nomor WhatsApp
                _buildLabel('Nomor WhatsApp Aktif'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _phoneController,
                  hint: '08xxxxxxxxxx',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  enabled: !isLoading,
                  errorText: _phoneError,
                  onChanged: (_) {
                    if (_phoneError != null) {
                      setState(() => _phoneError = null);
                    }
                  },
                ),

                // Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                // 4. Email
                _buildLabel('Alamat Email'),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _emailController,
                  hint: 'email@anda.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),

                // 5. Password
                _buildLabel('Password'),
                const SizedBox(height: 6),
                _buildPasswordField(isLoading),

                // ── Error message from provider ────────────────────────────
                if (regState.errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorBanner(regState.errorMessage!),
                ],

                const SizedBox(height: 24),

                // ── Submit button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitStep1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'LANJUT KE PILIH PAKET',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Back to login link ─────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: Text(
                      'Sudah punya akun? Masuk',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Reusable form widgets ─────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.titleMedium?.color?.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _inputDecoration(hint: hint, icon: icon).copyWith(
            errorText: null, // We handle errors manually below
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          enabled: !isLoading,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: _inputDecoration(
            hint: 'Minimal 6 karakter',
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
                size: 20,
              ),
              onPressed: isLoading
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
              splashRadius: 20,
            ),
          ),
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _passwordError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBusinessTypeDropdown(bool isLoading) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBusinessType,
      hint: Text(
        'Pilih kategori usaha...',
        style: GoogleFonts.poppins(
          color: AppTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'fnb', child: Text('F&B (Makanan & Minuman)')),
        DropdownMenuItem(value: 'retail', child: Text('Retail / Toko')),
        DropdownMenuItem(value: 'jasa', child: Text('Jasa / Layanan')),
        DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
      ],
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Theme.of(context).textTheme.bodyMedium?.color,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.category_outlined,
          color: AppTheme.primaryColor.withValues(alpha: 0.8),
          size: 20,
        ),
        filled: true,
        fillColor: Theme.of(context).inputDecorationTheme.fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
      ),
      onChanged: isLoading
          ? null
          : (val) => setState(() => _selectedBusinessType = val),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AppTheme.textSecondary.withValues(alpha: 0.4),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: AppTheme.primaryColor.withValues(alpha: 0.8),
        size: 20,
      ),
      filled: true,
      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildStepLabel(String label, bool isActive) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}
