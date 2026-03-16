import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'POSify';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.posify.umkm';

  // API
  static String get baseUrl {
    final url = dotenv.get('BASE_URL', fallback: 'http://10.0.2.2:3000/api/v1');
    return url.endsWith('/') ? url : '$url/';
  }
  static String get appClientKey => dotenv.get('APP_CLIENT_KEY', fallback: '');

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
