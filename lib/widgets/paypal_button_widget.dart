import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:async';
import 'dart:ui_web' as ui_web;
import '../config/paypal_config.dart';

/// Widget that renders PayPal buttons using PayPal SDK in an iframe
class PayPalButtonWidget extends StatefulWidget {
  final String containerId;
  final double amount;
  final String voucherId;
  final Function(String orderId) onPaymentSuccess;
  final Function(String error) onPaymentError;
  final VoidCallback onCancel;
  final VoidCallback? onModalOpening;

  const PayPalButtonWidget({
    super.key,
    required this.containerId,
    required this.amount,
    required this.voucherId,
    required this.onPaymentSuccess,
    required this.onPaymentError,
    required this.onCancel,
    this.onModalOpening,
  });

  @override
  State<PayPalButtonWidget> createState() => _PayPalButtonWidgetState();
}

class _PayPalButtonWidgetState extends State<PayPalButtonWidget> {
  bool _isInitialized = false;
  html.IFrameElement? _iframeElement;
  double _iframeHeight = 200.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePayPal();
    });
  }

  @override
  void dispose() {
    _iframeElement?.remove();
    super.dispose();
  }

  void _initializePayPal() {
    // Wait for PayPal SDK to load (with retries)
    _waitForPayPalSDK()
        .then((_) {
          if (!mounted) return;
          _createPayPalIframe();
        })
        .catchError((error) {
          if (mounted) {
            widget.onPaymentError(
              'PayPal SDK non chargé. Veuillez rafraîchir la page.',
            );
          }
        });
  }

  Future<void> _waitForPayPalSDK() async {
    const maxRetries = 40;
    const retryDelay = Duration(milliseconds: 200);

    final scripts = html.document.querySelectorAll('script[src*="paypal"]');
    if (scripts.isEmpty) {
      html.window.console.warn('PayPal script tag not found in DOM');
      await Future.delayed(const Duration(milliseconds: 1000));
    } else {
      html.window.console.log('PayPal script tag found, waiting for SDK...');
    }

    for (int i = 0; i < maxRetries; i++) {
      if (!mounted) {
        throw Exception('Widget disposed');
      }

      try {
        final paypalType = js.context.callMethod('eval', ['typeof paypal']);

        if (paypalType == 'undefined') {
          if (i % 5 == 0 && i > 0) {
            html.window.console.log(
              'Waiting for PayPal SDK... (attempt $i/$maxRetries) - paypal is undefined',
            );
          }
        } else {
          html.window.console.log('PayPal object found! Type: $paypalType');
          final buttonsType = js.context.callMethod('eval', [
            'typeof paypal.Buttons',
          ]);
          html.window.console.log('PayPal.Buttons type: $buttonsType');

          if (buttonsType != 'undefined') {
            html.window.console.log('PayPal SDK is ready!');
            return;
          } else {
            html.window.console.warn('PayPal exists but Buttons is undefined');
          }
        }
      } catch (e) {
        if (i % 10 == 0) {
          html.window.console.warn('PayPal SDK check error (attempt $i): $e');
        }
      }

      await Future.delayed(retryDelay);
    }

    final scriptsAfter = html.document.querySelectorAll(
      'script[src*="paypal"]',
    );
    if (scriptsAfter.isEmpty) {
      throw Exception(
        'PayPal script tag not found. Script may not have loaded.',
      );
    } else {
      throw Exception(
        'PayPal SDK not available after ${maxRetries} retries. Script tag exists but paypal object is not defined.',
      );
    }
  }

  void _createPayPalIframe() {
    if (!mounted) return;

    // Create iframe to display PayPal buttons
    _iframeElement = html.IFrameElement()
      ..id = '${widget.containerId}-iframe'
      ..style.width = '100%'
      ..style.height = '${_iframeHeight}px'
      ..style.border = 'none'
      ..style.overflow =
          'auto' // Allow scrolling if needed
      ..allow = 'payment';
    _iframeElement!.setAttribute(
      'sandbox',
      'allow-scripts allow-same-origin allow-forms allow-popups allow-popups-to-escape-sandbox',
    );

    // Register iframe with Flutter's platform view registry
    ui_web.platformViewRegistry.registerViewFactory(
      widget.containerId,
      (int viewId) => _iframeElement!,
    );

    // Create HTML content for iframe with PayPal buttons
    final iframeContent =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      margin: 0;
      padding: 16px;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    #paypal-buttons-container {
      width: 100%;
      min-height: 200px;
    }
  </style>
  <script src="${PayPalConfig.sdkUrl}"></script>
</head>
<body>
  <div id="paypal-buttons-container"></div>
  <script>
    (function() {
      if (typeof paypal === 'undefined') {
        console.error('PayPal SDK not loaded');
        return;
      }
      
      paypal.Buttons({
        style: {
          layout: 'vertical',
          color: 'blue',
          shape: 'rect',
          label: 'paypal',
          tagline: false
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
              custom_id: '${widget.voucherId}',
              category: 'DIGITAL_GOODS'
            }],
            application_context: {
              brand_name: 'Harmonya',
              landing_page: 'NO_PREFERENCE',
              user_action: 'PAY_NOW',
              shipping_preference: 'NO_SHIPPING'
            }
          });
        },
        onApprove: function(data, actions) {
          return actions.order.capture().then(function(details) {
            if (details.status === 'COMPLETED') {
              // Send message to parent window
              window.parent.postMessage({
                type: 'paypal-success',
                orderId: details.id,
                voucherId: '${widget.voucherId}'
              }, '*');
            } else {
              window.parent.postMessage({
                type: 'paypal-error',
                error: 'Le paiement n\\'a pas pu être complété'
              }, '*');
            }
          }).catch(function(error) {
            window.parent.postMessage({
              type: 'paypal-error',
              error: error.toString()
            }, '*');
          });
        },
        onError: function(err) {
          window.parent.postMessage({
            type: 'paypal-error',
            error: err.toString()
          }, '*');
        },
        onCancel: function(data) {
          // Don't send cancel event - the close button in card modal
          // should just close the modal, not cancel the entire payment flow
          // User can use the "Annuler" button on the page to cancel
          console.log('PayPal payment canceled, but ignoring to allow modal close');
        },
        onClick: function(data, actions) {
          // Detect when card payment button is clicked
          // Check if it's the card funding source
          if (data && data.fundingSource === 'card') {
            // Notify parent to increase iframe height
            window.parent.postMessage({
              type: 'paypal-card-opened'
            }, '*');
          }
        }
      }).render('#paypal-buttons-container');
      
      // Also listen for when card form is actually rendered/expanded
      // Use MutationObserver to detect when card form appears
      var observer = new MutationObserver(function(mutations) {
        var cardForm = document.querySelector('[data-funding-source="card"]');
        var cardFields = document.querySelector('.card-fields-container, [class*="card"], [id*="card"]');
        if (cardForm || cardFields) {
          window.parent.postMessage({
            type: 'paypal-card-opened'
          }, '*');
        }
      });
      
      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
      
      // Also check periodically for card form
      setTimeout(function() {
        var checkCardForm = setInterval(function() {
          var cardFields = document.querySelector('.card-fields-container, [class*="card"], [id*="card"], iframe[src*="card"]');
          if (cardFields) {
            window.parent.postMessage({
              type: 'paypal-card-opened'
            }, '*');
            clearInterval(checkCardForm);
          }
        }, 500);
        
        // Stop checking after 10 seconds
        setTimeout(function() {
          clearInterval(checkCardForm);
        }, 10000);
      }, 1000);
    })();
  </script>
</body>
</html>
    ''';

    // Set iframe content using srcdoc (for same-origin) or create blob URL
    _iframeElement!.srcdoc = iframeContent;

    // Listen for messages from iframe
    html.window.addEventListener('message', (event) {
      final data = (event as html.MessageEvent).data;
      if (data is Map) {
        final type = data['type'] as String?;
        if (type == 'paypal-success') {
          final orderId = data['orderId'] as String? ?? '';
          widget.onPaymentSuccess(orderId);
        } else if (type == 'paypal-error') {
          final error = data['error'] as String? ?? 'Erreur inconnue';
          widget.onPaymentError(error);
        } else if (type == 'paypal-cancel') {
          widget.onCancel();
        } else if (type == 'paypal-card-opened') {
          // Increase iframe height when card form is opened
          if (mounted && _iframeElement != null) {
            setState(() {
              _iframeHeight = 600.0; // Increased height for card form
            });
            _iframeElement!.style.height = '${_iframeHeight}px';
          }
        }
      }
    });

    // Add CSS to style PayPal's modal overlay
    final styleElement = html.StyleElement()
      ..id = 'paypal-modal-styles'
      ..text = '''
        .zoid-outlet,
        .zoid-visible-frame,
        .zoid-component-frame,
        [class*="zoid"],
        [id*="zoid"] {
          background-color: rgba(0, 0, 0, 0.85) !important;
          position: fixed !important;
          top: 0 !important;
          left: 0 !important;
          right: 0 !important;
          bottom: 0 !important;
          width: 100vw !important;
          height: 100vh !important;
          display: flex !important;
          align-items: center !important;
          justify-content: center !important;
          z-index: 999999 !important;
        }
        .zoid-outlet iframe,
        [class*="zoid"] iframe {
          background-color: white !important;
          border-radius: 8px !important;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5) !important;
          margin: auto !important;
        }
      ''';

    final existingStyle = html.document.querySelector('#paypal-modal-styles');
    if (existingStyle != null) {
      existingStyle.remove();
    }
    html.document.head!.append(styleElement);

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _iframeHeight,
      width: double.maxFinite,
      child: _isInitialized && _iframeElement != null
          ? HtmlElementView(viewType: widget.containerId)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
