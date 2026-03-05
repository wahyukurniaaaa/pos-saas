import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/license_activation_screen.dart';
import 'features/auth/screens/owner_setup_screen.dart';
import 'features/auth/screens/pin_login_screen.dart';
import 'features/pos/screens/pos_dashboard_screen.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/auth/providers/owner_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      home: const AppBootstrap(),
      routes: {
        '/license': (context) => const LicenseActivationScreen(),
        '/owner-setup': (context) => const OwnerSetupScreen(),
        '/pin-login': (context) => const PinLoginScreen(),
        '/pos': (context) => const PosDashboardScreen(),
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
      error: (_, __) => const LicenseActivationScreen(),
      data: (license) {
        if (license == null) {
          return const LicenseActivationScreen();
        }

        return ownerAsync.when(
          loading: () => const _SplashScreen(),
          error: (_, __) => const OwnerSetupScreen(),
          data: (owner) {
            if (owner == null) {
              return const OwnerSetupScreen();
            }
            return const PinLoginScreen();
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
