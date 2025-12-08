/// PayPal Configuration
///
/// To configure PayPal payments:
/// 1. Go to https://developer.paypal.com/
/// 2. Log in with your PayPal Business account
/// 3. Navigate to "My Apps & Credentials"
/// 4. Create an app or select an existing one
/// 5. Copy the "Client ID" (for Sandbox or Live mode)
/// 6. Replace the value below with your actual Client ID
class PayPalConfig {
  // PayPal Client ID
  // For Sandbox (testing): Use your Sandbox Client ID
  // For Production: Use your Live Client ID
  static const String clientId =
      'AV9bDFhYlO_Dqu9kKggFaAdyJQL9yXJtvw36KRRvf5ocF7SBAQlEbWYLdSou7KEgNz_jrZGzj3OznKmT';

  // PayPal environment
  // Set to 'sandbox' for testing, 'production' for live
  static const String environment = 'sandbox'; // or 'production'

  /// Get the PayPal SDK URL based on the environment
  static String get sdkUrl {
    final baseUrl = environment == 'sandbox'
        ? 'https://www.sandbox.paypal.com/sdk/js'
        : 'https://www.paypal.com/sdk/js';

    return '$baseUrl?client-id=$clientId&currency=EUR&locale=fr_FR';
  }

  /// Check if PayPal is configured
  static bool get isConfigured => clientId != 'YOUR_CLIENT_ID';
}
