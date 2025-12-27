import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/massage.dart';
import 'service_card_reveal.dart';
import 'booking_form.dart';

// Custom ScrollBehavior to hide scrollbars
class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // Return child without scrollbar
  }
}

class ServicesCard extends StatefulWidget {
  final bool isSmallScreen;
  final String title;
  final List<Massage> services;
  final GlobalKey? bookingSectionKey;
  final bool isTreatment; // true for treatments, false for massages

  const ServicesCard({
    super.key,
    required this.isSmallScreen,
    required this.title,
    required this.services,
    this.bookingSectionKey,
    this.isTreatment = false,
  });

  @override
  State<ServicesCard> createState() => _ServicesCardState();
}

class _ServicesCardState extends State<ServicesCard> {
  String? _expandedCardId; // Track which card is expanded (for mobile)

  void _handleCardExpanded(String cardId) {
    // On mobile, collapse other cards when a new one is expanded
    if (widget.isSmallScreen) {
      setState(() {
        _expandedCardId = _expandedCardId == cardId ? null : cardId;
      });
    }
  }

  void _openBookingForm(BuildContext context, Massage service) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    // Determine service type and get first price option as default
    final serviceType = widget.isTreatment ? 'soins' : 'massage';
    final firstPrice = service.prices.isNotEmpty ? service.prices.first : null;
    final selectedService = firstPrice != null
        ? service.getMassageOptionId(firstPrice.duration)
        : null;

    if (isSmallScreen) {
      // Open in a new page for small screens
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Réserver'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: ScrollConfiguration(
              behavior: NoScrollbarScrollBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: BookingForm(
                  isSmallScreen: isSmallScreen,
                  initialServiceType: serviceType,
                  initialSelectedService: selectedService,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Open in a dialog for big screens
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Réserver',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: NoScrollbarScrollBehavior(),
                      child: SingleChildScrollView(
                        child: BookingForm(
                          isSmallScreen: isSmallScreen,
                          showInDialog: true,
                          initialServiceType: serviceType,
                          initialSelectedService: selectedService,
                          onSuccess: () => Navigator.of(dialogContext).pop(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.services.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmallScreen ? 8 : 16,
            vertical: widget.isSmallScreen ? 16 : 24,
          ),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontSize: widget.isSmallScreen ? 24 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // On mobile (small screen), always show 1 per row
            // On larger screens, show 2-3 depending on width
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = widget.isSmallScreen || screenWidth < 600
                ? 1
                : (screenWidth > 1200 ? 3 : 2);
            final childAspectRatio = widget.isSmallScreen || screenWidth < 600
                ? 0.75
                : 0.85;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: widget.isSmallScreen ? 8 : 16,
                mainAxisSpacing: widget.isSmallScreen ? 8 : 16,
              ),
              padding: EdgeInsets.all(widget.isSmallScreen ? 8 : 16),
              itemCount: widget.services.length,
              itemBuilder: (context, index) {
                final service = widget.services[index];
                final cardId = service.id;
                final isExpanded =
                    widget.isSmallScreen && _expandedCardId == cardId;

                return ServiceCardReveal(
                  service: service,
                  isSmallScreen: widget.isSmallScreen,
                  isExpanded: isExpanded,
                  onExpanded: widget.isSmallScreen
                      ? () => _handleCardExpanded(cardId)
                      : null,
                  onBookNow: () => _openBookingForm(context, service),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
