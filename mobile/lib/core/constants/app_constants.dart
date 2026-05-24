import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Lumio';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.lumio.umkm';

  // API
  static String get baseUrl {
    final url = dotenv.get('BASE_URL', fallback: 'http://10.0.2.2:3000/api/v1');
    return url.endsWith('/') ? url : '$url/';
  }

  /// Base URL for the LumioPos Web API (Next.js).
  /// Used for Checkout_API and Status_API calls from mobile.
  static String get webBaseUrl {
    final url = dotenv.get(
      'WEB_BASE_URL',
      fallback: 'http://10.0.2.2:3000',
    );
    // Strip trailing slash for use with explicit paths
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get appClientKey => dotenv.get('APP_CLIENT_KEY', fallback: '');

  // Supabase
  static String get supabaseUrl => dotenv.get(
        'SUPABASE_URL',
        fallback: 'https://lyakoidtbdsdtnbourav.supabase.co',
      );
  static String get supabaseAnonKey =>
      dotenv.get('SUPABASE_ANON_KEY', fallback: '');

  // Google OAuth
  static String get googleWebClientId =>
      dotenv.get('GOOGLE_WEB_CLIENT_ID', fallback: '');
  static String get googleIosClientId =>
      dotenv.get('GOOGLE_IOS_CLIENT_ID', fallback: '');

  // PIN
  static const int pinLength = 6;
  static const int maxLoginAttempts = 5;
  static const int lockoutMinutes = 15;

  // Roles
  static const String roleOwner = 'owner';
  static const String roleSupervisor = 'supervisor';
  static const String roleCashier = 'cashier';

  // Receipt
  static const String receiptPrefix = 'POS';
}
