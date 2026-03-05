import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/license_activation_screen.dart';
import 'features/auth/screens/owner_setup_screen.dart';
import 'features/auth/screens/pin_login_screen.dart';
import 'features/pos/screens/pos_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/license',
      routes: {
        '/license': (context) => const LicenseActivationScreen(),
        '/owner-setup': (context) => const OwnerSetupScreen(),
        '/pin-login': (context) => const PinLoginScreen(),
        '/pos': (context) => const PosDashboardScreen(),
      },
    );
  }
}
