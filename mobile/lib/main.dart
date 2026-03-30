import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/unified_registration_screen.dart';
import 'features/auth/screens/owner_setup_screen.dart';
import 'features/auth/screens/pin_login_screen.dart';
import 'features/auth/screens/employee_selection_screen.dart';
import 'features/pos/screens/pos_dashboard_screen.dart';
import 'features/dashboard/screens/owner_dashboard_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/providers/owner_provider.dart';
import 'core/database/database.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await dotenv.load(fileName: ".env");
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
        '/register': (context) => const UnifiedRegistrationScreen(),
        '/license': (context) => const UnifiedRegistrationScreen(),
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

/// Bootstrap widget that checks license & owner status
/// and routes to the correct screen on startup.
class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final licenseAsync = ref.watch(licenseProvider);
    final ownerAsync = ref.watch(ownerProvider);

    return licenseAsync.when(
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => const UnifiedRegistrationScreen(),
      data: (license) {
        if (license == null) {
          return const UnifiedRegistrationScreen();
        }

        return ownerAsync.when(
          loading: () => const _SplashScreen(),
          error: (error, stackTrace) => const OwnerSetupScreen(),
          data: (owner) {
            if (owner == null) {
              return const OwnerSetupScreen();
            }
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
