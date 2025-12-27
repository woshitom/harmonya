import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/massage.dart';

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
    // Return child without scrollbar
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Hide overscroll indicator as well
    return child;
  }
}

// Custom scroll physics that allows parent scrolling when at boundaries
// This enables page scrolling when the card's scroll is at top/bottom
class AllowParentScrollPhysics extends ClampingScrollPhysics {
  const AllowParentScrollPhysics({super.parent});

  @override
  AllowParentScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AllowParentScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // When at boundaries, don't clamp - allow overscroll to enable parent scrolling
    if (value < position.pixels &&
        position.pixels <= position.minScrollExtent) {
      // At top, trying to scroll up - return 0 to allow parent scroll
      return 0.0;
    }
    if (value > position.pixels &&
        position.pixels >= position.maxScrollExtent) {
      // At bottom, trying to scroll down - return 0 to allow parent scroll
      return 0.0;
    }
    // Normal clamping for middle positions
    return super.applyBoundaryConditions(position, value);
  }
}

class ServiceCardReveal extends StatefulWidget {
  final Massage service;
  final bool isSmallScreen;
  final VoidCallback? onBookNow;
  final bool isExpanded; // Controlled by parent for mobile
  final VoidCallback? onExpanded; // Callback when card is expanded (for mobile)

  const ServiceCardReveal({
    super.key,
    required this.service,
    required this.isSmallScreen,
    this.onBookNow,
    this.isExpanded = false,
    this.onExpanded,
  });

  @override
  State<ServiceCardReveal> createState() => _ServiceCardRevealState();
}

class _ServiceCardRevealState extends State<ServiceCardReveal>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _translateAnimation;
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _translateAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, 1.0), // Start from bottom (100% down)
          end: Offset.zero, // End at top (0% down)
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void didUpdateWidget(ServiceCardReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync internal state with parent-controlled state (for mobile)
    if (widget.isSmallScreen && widget.isExpanded != _isExpanded) {
      _isExpanded = widget.isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        // Start auto-scroll after 5 seconds
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.jumpTo(0);
            _autoScrollTimer?.cancel();
            _autoScrollTimer = Timer(const Duration(seconds: 5), () {
              _startAutoScroll();
            });
          }
        });
      } else {
        _animationController.reverse();
        _autoScrollTimer?.cancel();
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (!mounted || !_isExpanded || !_scrollController.hasClients) {
      return;
    }

    // Scroll down slowly
    _scrollController
        .animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 2000,
          ), // Slower scroll (2 seconds)
          curve: Curves.easeInOut,
        )
        .then((_) {
          // After reaching bottom, wait 3 seconds then scroll to top
          _autoScrollTimer?.cancel();
          _autoScrollTimer = Timer(const Duration(seconds: 3), () {
            if (mounted && _isExpanded && _scrollController.hasClients) {
              _scrollController
                  .animateTo(
                    0,
                    duration: const Duration(
                      milliseconds: 2000,
                    ), // Slow scroll back to top
                    curve: Curves.easeInOut,
                  )
                  .then((_) {
                    // After reaching top, wait 5 seconds then start again
                    _autoScrollTimer?.cancel();
                    _autoScrollTimer = Timer(const Duration(seconds: 5), () {
                      _startAutoScroll(); // Loop: scroll down again
                    });
                  });
            }
          });
        });
  }

  void _handleTap() {
    // On mobile, notify parent to manage expansion state
    if (widget.isSmallScreen && widget.onExpanded != null) {
      if (!_isExpanded) {
        widget
            .onExpanded!(); // Notify parent to expand this card and collapse others
      } else {
        // Collapse this card
        setState(() {
          _isExpanded = false;
          _animationController.reverse();
          _autoScrollTimer?.cancel();
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    } else {
      // Desktop: manage state locally
      setState(() {
        _isExpanded = !_isExpanded;
        if (_isExpanded) {
          _animationController.forward();
          // Cancel any existing timer
          _autoScrollTimer?.cancel();
          // Wait for the scroll view to be built before resetting scroll position
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.jumpTo(0);
              // Start auto-scroll after 5 seconds
              _autoScrollTimer = Timer(const Duration(seconds: 5), () {
                _startAutoScroll();
              });
            }
          });
        } else {
          _animationController.reverse();
          // Cancel auto-scroll timer when collapsed
          _autoScrollTimer?.cancel();
          // Reset scroll position only if controller is attached
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        }
      });
    }
  }

  Color _getDefaultColor() {
    // Generate a color based on the service name hash
    final hash = widget.service.name.hashCode;
    final colors = [
      const Color(0xFFE8B4B8), // Soft pink
      const Color(0xFFB4D4E8), // Soft blue
      const Color(0xFFD4E8B4), // Soft green
      const Color(0xFFE8D4B4), // Soft beige
      const Color(0xFFB4B4E8), // Soft purple
      const Color(0xFFE8B4D4), // Soft lavender
    ];
    return colors[hash.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = widget.isSmallScreen ? 250.0 : 300.0;
    final firestoreImageUrl = widget.service.imageUrl;
    final assetImagePath = 'assets/${widget.service.id}.jpg';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (event) {
        if (!widget.isSmallScreen && !_isExpanded) {
          _handleTap();
        }
      },
      onExit: (event) {
        if (!widget.isSmallScreen && _isExpanded) {
          _handleTap();
        }
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Container(
              height: cardHeight,
              margin: EdgeInsets.all(widget.isSmallScreen ? 8 : 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Background Image or Color with zoom effect
                  AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) {
                      // Zoom in when expanded (scale from 1.0 to 1.1)
                      final scale = 1.0 + (0.1 * _slideAnimation.value);
                      return Positioned.fill(
                        child: Transform.scale(
                          scale: scale,
                          child: firestoreImageUrl != null
                              ? Image.network(
                                  firestoreImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      assetImagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    _getDefaultColor(),
                                                    _getDefaultColor()
                                                        .withOpacity(0.8),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                    );
                                  },
                                )
                              : Image.asset(
                                  assetImagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            _getDefaultColor(),
                                            _getDefaultColor().withOpacity(0.8),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                          ],
                          stops: const [0.0, 0.4, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Badges for Best Seller and New (top right - only visible when collapsed)
                  if (!_isExpanded)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.service.isBestSeller)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Meilleure vente',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (widget.service.isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nouveau',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.isSmallScreen ? 10 : 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  // Title, price and duration at bottom (only visible when collapsed)
                  if (!_isExpanded)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              widget.service.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: widget.isSmallScreen ? 18 : 22,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            // Price and Duration row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Price
                                Text(
                                  widget.service.priceRange,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: widget.isSmallScreen
                                            ? 16
                                            : 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                // Duration badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.service.durationRange,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: widget.isSmallScreen
                                              ? 11
                                              : 12,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Bottom sheet - slides up from bottom within the card
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Bottom sheet takes full card height when expanded
                      final contentHeight = cardHeight;
                      // Calculate bottom position: when collapsed (value=0), it's below the card (-contentHeight)
                      // When expanded (value=1), it's at the bottom (0)
                      final bottomPosition =
                          -contentHeight * (1 - _slideAnimation.value);

                      // Only render if animation is in progress or expanded
                      if (_slideAnimation.value == 0.0 && !_isExpanded) {
                        return const SizedBox.shrink();
                      }

                      return Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: bottomPosition,
                        child: SlideTransition(
                          position: _translateAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(
                                        0.1,
                                      ), // Very transparent at top
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.6),
                                      Colors.black.withOpacity(
                                        0.85,
                                      ), // Almost opaque at bottom
                                      Colors.black.withOpacity(
                                        0.95,
                                      ), // Almost opaque at bottom
                                    ],
                                    stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Fixed title at top with badges
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        20,
                                        16,
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: FadeTransition(
                                                  opacity: _fadeAnimation,
                                                  child: Text(
                                                    widget.service.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize:
                                                              widget
                                                                  .isSmallScreen
                                                              ? 18
                                                              : 22,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              // Badges in expanded view
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (widget
                                                      .service
                                                      .isBestSeller)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            left: 6,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.orange,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Meilleure vente',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              widget
                                                                  .isSmallScreen
                                                              ? 10
                                                              : 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  if (widget.service.isNew)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            left: 6,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.green,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        'Nouveau',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              widget
                                                                  .isSmallScreen
                                                              ? 10
                                                              : 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Scrollable description and zones area
                                    Expanded(
                                      child: Theme(
                                        data: Theme.of(context).copyWith(
                                          scrollbarTheme: ScrollbarThemeData(
                                            thumbVisibility:
                                                MaterialStateProperty.all(
                                                  false,
                                                ),
                                            thickness:
                                                MaterialStateProperty.all(0),
                                          ),
                                        ),
                                        child: ScrollConfiguration(
                                          behavior: NoScrollbarScrollBehavior(),
                                          child: SingleChildScrollView(
                                            controller: _scrollController,
                                            physics: widget.isSmallScreen
                                                ? const AllowParentScrollPhysics()
                                                : const ClampingScrollPhysics(),
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              0,
                                              16,
                                              16,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Description
                                                if (widget
                                                    .service
                                                    .description
                                                    .isNotEmpty) ...[
                                                  FadeTransition(
                                                    opacity: _fadeAnimation,
                                                    child: Text(
                                                      widget
                                                          .service
                                                          .description,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            color: Colors.white,
                                                            fontSize:
                                                                widget
                                                                    .isSmallScreen
                                                                ? 14
                                                                : 16,
                                                            height: 1.5,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],
                                                // Zones
                                                if (widget
                                                    .service
                                                    .zones
                                                    .isNotEmpty) ...[
                                                  FadeTransition(
                                                    opacity: _fadeAnimation,
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Icon(
                                                          Icons.spa,
                                                          size: 18,
                                                          color: Colors.white,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            'Zone du corps: ${widget.service.zones}',
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize:
                                                                      widget
                                                                          .isSmallScreen
                                                                      ? 12
                                                                      : 14,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Fixed bottom section with price, duration, and button
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        0,
                                        16,
                                        16,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Price and Duration
                                          FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  widget.service.priceRange,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                        fontSize:
                                                            widget.isSmallScreen
                                                            ? 16
                                                            : 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    widget
                                                        .service
                                                        .durationRange,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize:
                                                              widget
                                                                  .isSmallScreen
                                                              ? 12
                                                              : 14,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // Book Now Button
                                          FadeTransition(
                                            opacity: _fadeAnimation,
                                            child: SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: widget.onBookNow,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical:
                                                        widget.isSmallScreen
                                                        ? 12
                                                        : 16,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Réserver maintenant',
                                                  style: TextStyle(
                                                    fontSize:
                                                        widget.isSmallScreen
                                                        ? 14
                                                        : 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
