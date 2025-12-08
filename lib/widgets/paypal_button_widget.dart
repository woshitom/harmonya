import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;

/// Widget that renders PayPal buttons using PayPal SDK
class PayPalButtonWidget extends StatefulWidget {
  final String containerId;
  final double amount;
  final String voucherId;
  final Function(String orderId) onPaymentSuccess;
  final Function(String error) onPaymentError;
  final VoidCallback onCancel;

  const PayPalButtonWidget({
    super.key,
    required this.containerId,
    required this.amount,
    required this.voucherId,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    required this.onCancel,
  });

  @override
  State<PayPalButtonWidget> createState() => _PayPalButtonWidgetState();
}

class _PayPalButtonWidgetState extends State<PayPalButtonWidget> {
  bool _isInitialized = false;
  html.DivElement? _containerElement;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePayPal();
    });
  }

  @override
  void dispose() {
    _containerElement?.remove();
    super.dispose();
  }

  void _initializePayPal() {
    // Wait a bit for the widget to render
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // Check if PayPal SDK is loaded
      final paypal = js.context['paypal'];
      if (paypal == null) {
        widget.onPaymentError('PayPal SDK non chargé. Veuillez rafraîchir la page.');
        return;
      }

      // Create container element
      _containerElement = html.DivElement()
        ..id = widget.containerId
        ..style.width = '100%'
        ..style.minHeight = '200px';

      // Add container to body temporarily
      html.document.body!.append(_containerElement!);

      try {
        // Create PayPal buttons configuration using JavaScript directly
        final jsCode = '''
          (function() {
            if (typeof paypal === 'undefined') {
              return;
            }
            
            paypal.Buttons({
              style: {
                layout: 'vertical',
                color: 'blue',
                shape: 'rect',
                label: 'paypal'
              },
              createOrder: function(data, actions) {
                return actions.order.create({
                  intent: 'CAPTURE',
                  purchase_units: [{
                    amount: {
                      currency_code: 'EUR',
                      value: '${widget.amount.toStringAsFixed(2)}'
                    },
                    description: 'Bon cadeau Harmonya',
                    custom_id: '${widget.voucherId}'
                  }],
                  application_context: {
                    brand_name: 'Harmonya',
                    landing_page: 'NO_PREFERENCE',
                    user_action: 'PAY_NOW'
                  }
                });
              },
              onApprove: function(data, actions) {
                return actions.order.capture().then(function(details) {
                  if (details.status === 'COMPLETED') {
                    window.dispatchEvent(new CustomEvent('paypal-success', {
                      detail: { orderId: details.id, voucherId: '${widget.voucherId}' }
                    }));
                  } else {
                    window.dispatchEvent(new CustomEvent('paypal-error', {
                      detail: { error: 'Le paiement n\\'a pas pu être complété' }
                    }));
                  }
                }).catch(function(error) {
                  window.dispatchEvent(new CustomEvent('paypal-error', {
                    detail: { error: error.toString() }
                  }));
                });
              },
              onError: function(err) {
                window.dispatchEvent(new CustomEvent('paypal-error', {
                  detail: { error: err.toString() }
                }));
              },
              onCancel: function(data) {
                window.dispatchEvent(new CustomEvent('paypal-cancel'));
              }
            }).render('#${widget.containerId}');
          })();
        ''';

        // Execute JavaScript code using ScriptElement
        final script = html.ScriptElement()
          ..text = jsCode
          ..type = 'text/javascript';
        html.document.head!.append(script);
        
        // Remove script after execution
        Future.delayed(const Duration(milliseconds: 100), () {
          script.remove();
        });

        // Listen for PayPal events
        html.window.addEventListener('paypal-success', (event) {
          final customEvent = event as html.CustomEvent;
          final orderId = customEvent.detail['orderId'] as String? ?? '';
          widget.onPaymentSuccess(orderId);
        });

        html.window.addEventListener('paypal-error', (event) {
          final customEvent = event as html.CustomEvent;
          final error = customEvent.detail['error'] as String? ?? 'Erreur inconnue';
          widget.onPaymentError(error);
        });

        html.window.addEventListener('paypal-cancel', (event) {
          widget.onCancel();
        });

        setState(() {
          _isInitialized = true;
        });
      } catch (e) {
        widget.onPaymentError('Erreur d\'initialisation PayPal: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.maxFinite,
      child: _isInitialized && _containerElement != null
          ? HtmlElementView(
              viewType: widget.containerId,
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
