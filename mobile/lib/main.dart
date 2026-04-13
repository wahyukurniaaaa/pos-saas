import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
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
  void initState() {
    super.initState();
    // Start sync after the first frame so providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSyncLifecycle();
    });
  }

  void _handleSyncLifecycle() {
    final user = ref.read(authProvider).value;
    final syncService = ref.read(syncServiceProvider);
    if (user != null) {
      syncService.start();
    }
    // Watch for auth changes to start/stop sync accordingly
    ref.listen(authProvider, (_, next) {
      if (next.value != null) {
        syncService.start();
      } else {
        syncService.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(supabaseSessionProvider);
    final licenseAsync = ref.watch(licenseProvider);
    final ownerAsync = ref.watch(ownerProvider);

    // Layer 1: Account Session (Supabase)
    if (session == null) {
      return const LoginScreen();
    }

    // Layer 2: License (Device/Subscription)
    return licenseAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => const LicenseActivationScreen(),
      data: (license) {
        if (license == null) {
          return const LicenseActivationScreen();
        }

        // Layer 3: Owner (Store setup)
        return ownerAsync.when(
          loading: () => const _SplashScreen(),
          error: (error, stackTrace) => const OwnerSetupScreen(),
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
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
