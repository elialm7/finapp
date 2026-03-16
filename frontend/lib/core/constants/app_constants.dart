// lib/core/constants/app_constants.dart
class AppConstants {
  AppConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  static const String tokenKey = 'auth_token';
  static const String userEmailKey = 'user_email';
  static const String baseCurrencyKey = 'base_currency';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
  static const int defaultPageSize = 20;
}
