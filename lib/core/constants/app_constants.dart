/// App Constants and Pricing Rules for Gaming Lounge
class AppConstants {
  static const String appName = 'GCM';
  static const int totalScreensCount = 8;

  // Currency
  static const String currencyIQD = 'د.ع';

  // Pricing Rates per Hour (IQD)
  // 2 Players = 3,000 IQD/hr
  // 3 Players = 4,000 IQD/hr
  // 4 Players = 5,000 IQD/hr
  static const double rate2PlayersPerHour = 3000.0;
  static const double rate3PlayersPerHour = 4000.0;
  static const double rate4PlayersPerHour = 5000.0;

  /// Returns the hourly rate in IQD based on player count
  static double getRateForPlayers(int playerCount) {
    switch (playerCount) {
      case 2:
        return rate2PlayersPerHour;
      case 3:
        return rate3PlayersPerHour;
      case 4:
        return rate4PlayersPerHour;
      default:
        if (playerCount < 2) return rate2PlayersPerHour;
        return rate4PlayersPerHour;
    }
  }

  // Firestore Collection Names
  static const String screensCollection = 'screens';
  static const String sessionsCollection = 'sessions';
  static const String productsCollection = 'products';
  static const String usersCollection = 'users';
  static const String loungeSettingsCollection = 'settings';
  static const String restockTransactionsCollection = 'restock_transactions';
  static const String appConfigCollection = 'app_config';
  static const String versionInfoDoc = 'version_info';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleStaff = 'staff';
}
