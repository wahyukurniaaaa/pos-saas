import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/screens/unified_registration_screen.dart';
import 'package:posify_app/features/auth/screens/license_activation_screen.dart';
import 'package:posify_app/features/auth/screens/owner_setup_screen.dart';
import 'package:posify_app/features/auth/screens/pin_login_screen.dart';
import 'package:posify_app/features/auth/screens/employee_selection_screen.dart';
import 'package:posify_app/features/pos/screens/pos_dashboard_screen.dart';
import 'package:posify_app/features/dashboard/screens/owner_dashboard_screen.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/features/auth/screens/login_screen.dart';
import 'package:posify_app/core/constants/app_constants.dart';
import 'package:posify_app/core/providers/supabase_provider.dart';
import 'package:posify_app/core/services/sync_service.dart';
import 'package:posify_app/core/services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: PosifyApp()));
}

class PosifyApp extends StatelessWidget {
  const PosifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POSify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AppBootstrap(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const UnifiedRegistrationScreen(),
        '/license': (context) => const LicenseActivationScreen(),
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
  Widget build(BuildContext context) {
    // 1. Listen for future auth changes
    ref.listen(authProvider, (previous, next) {
      final user = next.value;
      if (user != null) {
        ref.read(syncServiceProvider).start();
        ref.read(realtimeServiceProvider).start();
      } else {
        ref.read(syncServiceProvider).stop();
        ref.read(realtimeServiceProvider).stop();
      }
    });

    // 2. Initial trigger for cold boot (if user is already logged in)
    final initialUser = ref.read(authProvider).value;
    if (initialUser != null) {
      // Use microtask or post-frame to avoid calling start() during build
      Future.microtask(() {
        ref.read(syncServiceProvider).start();
        ref.read(realtimeServiceProvider).start();
      });
    }

    final session = ref.watch(supabaseSessionProvider);
    final licenseAsync = ref.watch(licenseProvider);
    final ownerAsync = ref.watch(ownerProvider);

    // Layer 1: Account Session (Supabase)
    if (session == null) {
      return const LoginScreen();
    }

    // Tunggu sync pertama selesai JIKA database lokal benar-benar kosong (Perangkat Baru / Reinstall)
    // Kita hanya mengkonfirmasi data kosong jika state sudah TIDAK loading dan nilainya murni null
    final isLocalLicenseEmpty = !licenseAsync.isLoading && licenseAsync.value == null;
    final isLocalOwnerEmpty = !ownerAsync.isLoading && ownerAsync.value == null;
    final isInitialSyncDone = ref.watch(initialSyncProvider);

    if (isLocalLicenseEmpty && isLocalOwnerEmpty && !isInitialSyncDone) {
      return const _SplashScreen(errorMessage: 'Menyinkronkan data profil dari cloud...');
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
          return const LicenseActivationScreen();
        }

        // Layer 3: Owner (Store setup)
        return ownerAsync.when(
          loading: () => const _SplashScreen(),
          error: (error, stackTrace) => _SplashScreen(
            errorMessage: 'Gagal memuat profil toko.',
            onRetry: () => ref.invalidate(ownerProvider),
          ),
          data: (owner) {
            if (owner == null) {
              return const OwnerSetupScreen();
            }

            // Layer 4: Employee Selection (PIN Login)
            return const EmployeeSelectionScreen();
          },
        );
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
