import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/paypal_button_widget.dart';

class PayPalPaymentPage extends StatelessWidget {
  final String voucherId;
  final double amount;

  const PayPalPaymentPage({
    super.key,
    required this.voucherId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final containerId = 'paypal-container-$voucherId';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement PayPal'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Bon cadeau Harmonya',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            'Montant',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            NumberFormat.currency(
                              symbol: '€',
                              decimalDigits: 2,
                            ).format(amount),
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Choisissez votre méthode de paiement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vous pouvez payer avec votre compte PayPal ou par carte bancaire',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Payment Methods Explanation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Méthodes de paiement disponibles',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethodInfo(
                          context,
                          Icons.account_circle,
                          'Bouton PayPal (bleu)',
                          'Pour payer avec votre compte PayPal. Cliquez sur le bouton bleu "PayPal" ci-dessous.',
                          Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentMethodInfo(
                          context,
                          Icons.credit_card,
                          'Bouton Carte bancaire (gris)',
                          'Pour payer par carte bancaire sans compte PayPal. Cliquez sur le bouton gris "Carte bancaire" ci-dessous.',
                          Colors.grey[700]!,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // PayPal Buttons Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Sélectionnez votre méthode de paiement',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Wrap PayPal buttons in a container to ensure they're part of Flutter layout
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(
                            minHeight: 200,
                            maxHeight:
                                700, // Increased to accommodate card form
                          ),
                          child: PayPalButtonWidget(
                            containerId: containerId,
                            amount: amount,
                            voucherId: voucherId,
                            onPaymentSuccess: (orderId) async {
                              // Navigate back and show success
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pop(true); // true = success
                              }
                            },
                            onPaymentError: (error) {
                              // Navigate back and show error
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pop(false); // false = error
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur de paiement: $error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            onCancel: () {
                              // Navigate back
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            onModalOpening: () {
                              // No action needed - PayPal modal will appear on this page
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Annuler'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodInfo(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
