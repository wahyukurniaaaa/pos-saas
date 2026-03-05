class AppConstants {
  AppConstants._();

  static const String appName = 'POSify';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.posify.umkm';

  // API
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator -> localhost
  static const String appClientKey = 'e3ccc142697425eb3aa9d059aee7db30d12f2d70cd60aea7';

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
