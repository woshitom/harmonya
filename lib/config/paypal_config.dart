import 'package:flutter_dotenv/flutter_dotenv.dart';

/// PayPal Configuration
///
/// Values are loaded from environment variables (--dart-define) or .env file
///
/// For production, use --dart-define flags:
/// flutter build web --dart-define=PAYPAL_CLIENT_ID=your_client_id --dart-define=PAYPAL_ENVIRONMENT=production
class PayPalConfig {
  // PayPal Client ID
  // Load from environment variables or .env file
  static String get clientId =>
      const String.fromEnvironment('PAYPAL_CLIENT_ID', defaultValue: '') != ''
      ? const String.fromEnvironment('PAYPAL_CLIENT_ID')
      : dotenv.env['PAYPAL_CLIENT_ID'] ?? '';

  // PayPal environment
  // Set to 'sandbox' for testing, 'production' for live
  static String get environment =>
      const String.fromEnvironment('PAYPAL_ENVIRONMENT', defaultValue: '') != ''
      ? const String.fromEnvironment('PAYPAL_ENVIRONMENT')
      : dotenv.env['PAYPAL_ENVIRONMENT'] ?? 'sandbox';

  /// Get the PayPal SDK URL based on the environment
  /// Includes funding sources to enable both PayPal account and card payments
  static String get sdkUrl {
    final baseUrl = environment == 'sandbox'
        ? 'https://www.sandbox.paypal.com/sdk/js'
        : 'https://www.paypal.com/sdk/js';

    // Enable both PayPal account payments and card payments
    // funding-source=paypal enables PayPal account payments
    // funding-source=card enables card payments
    return '$baseUrl?client-id=$clientId&currency=EUR&locale=fr_FR&enable-funding=paypal,card';
  }

  /// Check if PayPal is configured
  static bool get isConfigured =>
      clientId.isNotEmpty && clientId != 'YOUR_CLIENT_ID';
}
