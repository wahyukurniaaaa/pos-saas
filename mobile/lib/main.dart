import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/screens/registration_screen.dart';
import 'package:lumio/features/auth/screens/unlicensed_screen.dart';
import 'package:lumio/features/auth/screens/owner_setup_screen.dart';
import 'package:lumio/features/auth/screens/pin_login_screen.dart';
import 'package:lumio/features/auth/screens/employee_selection_screen.dart';
import 'package:lumio/features/pos/screens/pos_dashboard_screen.dart';
import 'package:lumio/features/dashboard/screens/owner_dashboard_screen.dart';
import 'package:lumio/features/auth/providers/auth_providers.dart';
import 'package:lumio/features/auth/providers/owner_provider.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/features/auth/screens/login_screen.dart';
import 'package:lumio/core/constants/app_constants.dart';
import 'package:lumio/core/providers/supabase_provider.dart';
import 'package:lumio/core/services/sync_service.dart';
import 'package:lumio/core/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lumio/services/update_checker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: LumioApp()));
}

class LumioApp extends StatelessWidget {
  const LumioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AppBootstrap(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/unlicensed': (context) => const UnlicensedScreen(),
        '/owner-setup': (context) => const OwnerSetupScreen(),
        '/pin-login': (context) {
          final employee = ModalRoute.of(context)!.settings.arguments;
          if (employee is Employee) {
            return PinLoginScreen(employee: employee);
          }
          // Fallback if no employee is provided
          return const EmployeeSelectionScreen();
        },
        '/employee-selection': (context) => const EmployeeSelectionScreen(),
        '/pos': (context) => const PosDashboardScreen(),
        '/dashboard': (context) => const OwnerDashboardScreen(),
      },
    );
  }
}

/// Bootstrap widget that checks:
/// 1. Supabase Session (Account)
/// 2. License Status (Pro features & Sync)
/// 3. Owner Setup (Store details)
/// Then routes to Employee Selection for PIN Login.
class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateChecker.check(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Listen for future license changes to start sync
    ref.listen(licenseProvider, (previous, next) {
      final license = next.value;
      final tier = license?.tierLevel?.toLowerCase();
      if (license != null && tier == 'pro') {
        ref.read(syncServiceProvider).start();
        ref.read(realtimeServiceProvider).start();
      } else if (!next.isLoading) {
        // For 'trial', 'lite', null, or any non-pro tier: stop sync services
        ref.read(syncServiceProvider).stop();
        ref.read(realtimeServiceProvider).stop();
      }
    });

    // 2. Initial trigger for cold boot (if license is already loaded)
    final initialLicense = ref.read(licenseProvider).value;
    if (initialLicense != null && initialLicense.tierLevel?.toLowerCase() == 'pro') {
      // Use microtask or post-frame to avoid calling start() during build
      Future.microtask(() {
        ref.read(syncServiceProvider).start();
        ref.read(realtimeServiceProvider).start();
      });
    }

    final session = ref.watch(supabaseSessionProvider);
    final licenseAsync = ref.watch(licenseProvider);
    final ownerAsync = ref.watch(ownerProvider);
    final storeProfileAsync = ref.watch(storeProfileProvider);

    // Layer 1: Account Session (Supabase)
    if (session == null) {
      return const LoginScreen();
    }

    // Layer 2: License (Device/Subscription)
    return licenseAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => _SplashScreen(
        errorMessage: 'Gagal memverifikasi lisensi. Periksa koneksi internet.',
        onRetry: () => ref.invalidate(licenseProvider),
      ),
      data: (license) {
        if (license == null) {
          return const UnlicensedScreen();
        }

        final tier = license.tierLevel?.toLowerCase();
        final isPro = tier == 'pro';
        final isTrial = tier == 'trial';

        // Trial expired: navigate to UnlicensedScreen with trial-expired indicator
        if (isTrial &&
            license.expiredAt != null &&
            license.expiredAt!.isBefore(DateTime.now())) {
          return const UnlicensedScreen(isTrialExpired: true);
        }

        final isInitialSyncDone = ref.watch(initialSyncProvider);

        // Still loading? Show splash.
        if (ownerAsync.isLoading || storeProfileAsync.isLoading) {
          return const _SplashScreen();
        }

        if (ownerAsync.hasError) {
          return _SplashScreen(
            errorMessage: 'Gagal memuat profil toko.',
            onRetry: () => ref.invalidate(ownerProvider),
          );
        }

        final owner = ownerAsync.value;
        final storeProfile = storeProfileAsync.value;

        // Tunggu sync selesai jika belum ada data sama sekali (fresh install).
        if (isPro && owner == null && storeProfile == null && !isInitialSyncDone) {
          return const _SplashScreen(
              errorMessage: 'Menyinkronkan data profil dari cloud...');
        }

        // Layer 3: Jika tidak ada owner DAN tidak ada store profile → perlu setup.
        if (owner == null && storeProfile == null) {
          return const OwnerSetupScreen();
        }

        // Auto-heal: Toko sudah disetup via web, tapi data karyawan owner lokal belum ada.
        if (storeProfile != null && owner == null) {
          Future.microtask(() {
            ref.read(ownerProvider.notifier).autoCreateOwnerFromCloud(storeProfile.name);
          });
          return const _SplashScreen(
            errorMessage: 'Menyiapkan profil pemilik (PIN default: 123456)...',
          );
        }

        // Layer 4: Data sudah ada → Employee Selection (PIN Login).
        return const EmployeeSelectionScreen();
      },

    );
  }
}

class _SplashScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _SplashScreen({this.errorMessage, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            if (errorMessage != null) ...[
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('COBA LAGI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
