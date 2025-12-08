import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import '../models/gift_voucher.dart';
import '../services/firebase_service.dart';
import '../config/paypal_config.dart';
import '../pages/paypal_payment_page.dart';

class GiftVoucherForm extends StatefulWidget {
  final bool isSmallScreen;

  const GiftVoucherForm({super.key, required this.isSmallScreen});

  @override
  State<GiftVoucherForm> createState() => _GiftVoucherFormState();
}

class _GiftVoucherFormState extends State<GiftVoucherForm> {
  final _formKey = GlobalKey<FormState>();
  final _purchaserNameController = TextEditingController();
  final _purchaserEmailController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientEmailController = TextEditingController();
  final _messageController = TextEditingController();
  final _firebaseService = FirebaseService();

  double _selectedAmount = 50.0;
  bool _isSubmitting = false;
  bool _paypalScriptLoaded = false;

  final List<double> _amountOptions = [50.0, 75.0, 95.0, 115.0, 150.0, 200.0];

  @override
  void initState() {
    super.initState();
    _loadPayPalScript();
  }

  @override
  void dispose() {
    _purchaserNameController.dispose();
    _purchaserEmailController.dispose();
    _recipientNameController.dispose();
    _recipientEmailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadPayPalScript() async {
    if (_paypalScriptLoaded) return;

    // Check if PayPal script is already loaded
    final scripts = html.document.querySelectorAll('script[src*="paypal"]');
    if (scripts.isNotEmpty) {
      setState(() {
        _paypalScriptLoaded = true;
      });
      return;
    }

    // Check if PayPal is configured
    if (!PayPalConfig.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PayPal n\'est pas configuré. Veuillez configurer votre Client ID dans lib/config/paypal_config.dart',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Load PayPal SDK
    final scriptUrl = PayPalConfig.sdkUrl;
    final clientId = PayPalConfig.clientId;
    print('Loading PayPal SDK from: $scriptUrl'); // Debug
    print(
      'PayPal Client ID: ${clientId.substring(0, 20)}...',
    ); // Debug (first 20 chars)

    // Verify client ID is not empty
    if (clientId.isEmpty || clientId == 'YOUR_CLIENT_ID') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PayPal Client ID non configuré. Vérifiez votre fichier .env',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Remove crossOrigin - PayPal SDK doesn't need it and it might cause issues
    final script = html.ScriptElement()
      ..src = scriptUrl
      ..type = 'text/javascript'
      ..async =
          false // Try synchronous loading
      ..defer = false;

    // Set up error handler BEFORE appending
    script.onError.listen((event) {
      print('PayPal script load error: $event'); // Debug
      html.window.console.error(
        'PayPal SDK failed to load. Check URL: $scriptUrl. Error: $event',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors du chargement de PayPal. Vérifiez la console pour plus de détails.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    // Set up load handler BEFORE appending
    script.onLoad.listen((event) {
      print('PayPal script tag loaded successfully'); // Debug
      html.window.console.log(
        'PayPal script loaded, waiting for SDK initialization... Event: $event',
      );

      // Check immediately after load with multiple delays
      Future.delayed(const Duration(milliseconds: 100), () {
        _checkPayPalSDK('100ms after load');
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        _checkPayPalSDK('500ms after load');
      });

      Future.delayed(const Duration(milliseconds: 1000), () {
        _checkPayPalSDK('1s after load');
      });

      // Don't set _paypalScriptLoaded here - wait for SDK to be available
      // The _waitForPayPalScript will check for actual SDK availability
    });

    html.document.head!.append(script);
    html.window.console.log('PayPal script tag added to DOM: $scriptUrl');
    html.window.console.log('Script element HTML: ${script.outerHtml}');

    // Also check if script was actually added
    Future.delayed(const Duration(milliseconds: 100), () {
      final addedScript = html.document.querySelector('script[src*="paypal"]');
      if (addedScript != null) {
        html.window.console.log('Script confirmed in DOM');
        final scriptSrc = (addedScript as html.ScriptElement).src;
        html.window.console.log('Script src: $scriptSrc');
      } else {
        html.window.console.error('Script NOT found in DOM after adding!');
      }
    });

    // Also check the script element after a delay
    Future.delayed(const Duration(seconds: 2), () {
      final scriptElement = html.document.querySelector(
        'script[src*="paypal"]',
      );
      if (scriptElement != null) {
        final outerHtml = scriptElement.outerHtml ?? '';
        final displayHtml = outerHtml.length > 100
            ? outerHtml.substring(0, 100)
            : outerHtml;
        html.window.console.log('Script element found in DOM: $displayHtml');
        // Check if script has any error attributes or status
        html.window.console.log('Checking if script executed...');
        try {
          final result = js.context.callMethod('eval', ['typeof paypal']);
          html.window.console.log('typeof paypal after 2 seconds: $result');
        } catch (e) {
          html.window.console.error('Error checking paypal type: $e');
        }
      }
    });
  }

  void _checkPayPalSDK(String timing) {
    try {
      final paypalCheck = js.context.callMethod('eval', [
        'typeof paypal !== "undefined" ? "exists" : "missing"',
      ]);
      html.window.console.log('PayPal object check ($timing): $paypalCheck');

      if (paypalCheck == 'exists') {
        final buttonsCheck = js.context.callMethod('eval', [
          'typeof paypal.Buttons !== "undefined" ? "exists" : "missing"',
        ]);
        html.window.console.log(
          'PayPal.Buttons check ($timing): $buttonsCheck',
        );

        if (buttonsCheck == 'exists' && mounted) {
          setState(() {
            _paypalScriptLoaded = true;
          });
        }
      }
    } catch (e) {
      html.window.console.error('Error checking PayPal ($timing): $e');
    }
  }

  Future<void> _waitForPayPalScript() async {
    // Wait for PayPal script to load, with timeout
    const maxWait = Duration(seconds: 15); // Increased timeout
    const checkInterval = Duration(milliseconds: 300);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWait) {
      if (!mounted) return;

      // Check if script tag exists
      final scripts = html.document.querySelectorAll('script[src*="paypal"]');
      if (scripts.isNotEmpty) {
        // Check if PayPal SDK is available
        try {
          // Use a delay to let the script execute
          await Future.delayed(const Duration(milliseconds: 800));
          // Try to access PayPal using eval
          final result = js.context.callMethod('eval', [
            'typeof paypal !== "undefined" && typeof paypal.Buttons !== "undefined" ? "ready" : "notready"',
          ]);
          if (result == 'ready') {
            setState(() {
              _paypalScriptLoaded = true;
            });
            return;
          }
        } catch (e) {
          // PayPal not ready yet, continue waiting
        }
      }
      await Future.delayed(checkInterval);
    }

    // Timeout reached
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Timeout lors du chargement de PayPal. Veuillez rafraîchir la page.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handlePayPalPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if PayPal Client ID is configured
    if (!PayPalConfig.isConfigured) {
      _showConfigurationDialog();
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Ensure PayPal script is loaded before showing dialog
      if (!_paypalScriptLoaded) {
        // Wait for script to load (with timeout)
        await _waitForPayPalScript();
      }

      // Create voucher with pending status
      final expiresAt = DateTime.now().add(const Duration(days: 365));
      final voucher = GiftVoucher(
        purchaserName: _purchaserNameController.text.trim(),
        purchaserEmail: _purchaserEmailController.text.trim(),
        recipientName: _recipientNameController.text.trim(),
        recipientEmail: _recipientEmailController.text.trim(),
        amount: _selectedAmount,
        message: _messageController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      // Save voucher to Firestore
      final voucherId = await _firebaseService.createGiftVoucher(voucher);

      // Show PayPal payment dialog
      _showPayPalDialog(voucherId, _selectedAmount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(child: Text('Configuration requise')),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pour activer les paiements PayPal, vous devez :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('1. Créer un compte PayPal Business'),
                Text('2. Obtenir votre Client ID sur developer.paypal.com'),
                Text('3. Ouvrir le fichier lib/config/paypal_config.dart'),
                Text('4. Remplacer "YOUR_CLIENT_ID" par votre Client ID'),
                SizedBox(height: 16),
                Text(
                  'Pour l\'instant, le paiement PayPal n\'est pas disponible.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [ElevatedButton(onPressed: null, child: Text('OK'))],
          ),
        ),
      ),
    );
  }

  Future<void> _showPayPalDialog(String voucherId, double amount) async {
    // Navigate to full-page PayPal payment screen
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            PayPalPaymentPage(voucherId: voucherId, amount: amount),
      ),
    );

    // Handle payment result
    if (result == true) {
      // Payment was successful - PayPalPaymentPage already handled the payment
      // Just show success message
      if (mounted) {
        await _handlePaymentSuccess(voucherId, '');
      }
    } else if (result == false) {
      // Payment failed (error already shown in PayPalPaymentPage)
      // No need to show error again
    }
    // If result is null, user cancelled (no action needed)
  }

  Future<void> _handlePaymentSuccess(String voucherId, String orderId) async {
    try {
      // Update voucher status to 'paid'
      await _firebaseService.updateGiftVoucher(voucherId, {
        'status': 'paid',
        'paidAt': DateTime.now().toIso8601String(),
        'paypalOrderId': orderId,
      });

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Expanded(child: Text('Paiement réussi !')),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre bon cadeau a été payé avec succès !',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Un email de confirmation a été envoyé à ${_recipientEmailController.text.trim()}.',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le bon cadeau est valable jusqu\'au ${DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 365)))}.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Reset form
                      _formKey.currentState?.reset();
                      _purchaserNameController.clear();
                      _purchaserEmailController.clear();
                      _recipientNameController.clear();
                      _recipientEmailController.clear();
                      _messageController.clear();
                      _selectedAmount = 50.0;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Ok'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur de paiement: $error'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(widget.isSmallScreen ? 16 : 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Offrez un bon cadeau',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: widget.isSmallScreen ? 24 : 32,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Faites plaisir à un proche avec un bon cadeau Harmonya',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: widget.isSmallScreen ? 24 : 32),

            // Amount selection
            Text(
              'Montant du bon cadeau',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _amountOptions.map((amount) {
                final isSelected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text(
                    '${NumberFormat.currency(symbol: '€', decimalDigits: 0).format(amount)}',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAmount = amount;
                      });
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Purchaser info
            Text(
              'Vos informations',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _purchaserNameController,
              decoration: const InputDecoration(
                labelText: 'Votre nom *',
                prefixIcon: Icon(Icons.person),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purchaserEmailController,
              decoration: const InputDecoration(
                labelText: 'Votre email *',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre email';
                }
                if (!value.contains('@')) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Recipient info
            Text(
              'Informations du destinataire',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recipientNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du destinataire *',
                prefixIcon: Icon(Icons.card_giftcard),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le nom du destinataire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _recipientEmailController,
              decoration: const InputDecoration(
                labelText: 'Email du destinataire *',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'Le bon cadeau sera envoyé à cette adresse',
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer l\'email du destinataire';
                }
                if (!value.contains('@')) {
                  return 'Veuillez entrer un email valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message personnalisé (optionnel)',
                prefixIcon: Icon(Icons.message),
                helperText: 'Un message à inclure avec le bon cadeau',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isSubmitting) {
                  _handlePayPalPayment();
                }
              },
            ),
            const SizedBox(height: 32),

            // PayPal button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handlePayPalPayment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Image.network(
                        'https://www.paypalobjects.com/webstatic/mktg/logo/pp_cc_mark_111x69.jpg',
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.payment);
                        },
                      ),
                label: Text(
                  _isSubmitting ? 'Traitement...' : 'Payer avec PayPal',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0070BA),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Le bon cadeau sera valable pendant 1 an à compter de la date d\'achat',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
