import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/services_card.dart';
import '../widgets/review_section.dart';
import '../widgets/review_form.dart';
import '../widgets/gift_voucher_form.dart';
import '../widgets/contact_form.dart';
import '../services/firebase_service.dart';
import '../models/massage.dart';
import 'admin_login_page.dart';
import 'admin_panel_page.dart';
import '../widgets/reviews_list.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _giftVoucherKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();
  final GlobalKey _reviewKey = GlobalKey();
  late TabController _tabController;
  double _titleOpacity = 0.0;

  // Data loaded once in initState
  Map<String, dynamic>? _averageRatingData;
  List<Massage>? _massages;
  List<Massage>? _treatments;
  bool _isLoadingData = true;

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment:
            0.1, // Scroll to show section slightly below the top (accounting for tab bar)
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    _tabController = TabController(length: isLoggedIn ? 6 : 5, vsync: this);

    // Add scroll listener to update title opacity
    _scrollController.addListener(_updateTitleOpacity);

    // Load data once in initState
    _loadData();

    // Listen to auth state changes to update tab controller
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        final newIsLoggedIn = user != null;
        final newLength = newIsLoggedIn ? 6 : 5;
        if (_tabController.length != newLength) {
          final oldIndex = _tabController.index;
          _tabController.dispose();
          _tabController = TabController(length: newLength, vsync: this);
          // Try to restore the previous index if still valid
          if (oldIndex < newLength) {
            _tabController.index = oldIndex;
          }
          setState(() {});
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      // Load all data in parallel
      final results = await Future.wait([
        FirebaseService().getAverageRatingOnce(),
        FirebaseService().getMassagesOnce(),
        FirebaseService().getTreatmentsOnce(),
      ]);

      if (mounted) {
        setState(() {
          _averageRatingData = results[0] as Map<String, dynamic>;
          _massages = results[1] as List<Massage>;
          _treatments = results[2] as List<Massage>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
          // Set defaults on error
          _averageRatingData = {'rating': 0.0, 'count': 0};
          _massages = [];
          _treatments = [];
        });
      }
    }
  }

  void _updateTitleOpacity() {
    if (!_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;

    if (currentOffset > 400) {
      // Smooth fade-in as we approach collapse threshold
      if (_titleOpacity != 1.0) {
        setState(() {
          _titleOpacity = 1.0.clamp(0.0, 1.0);
        });
      }
    } else {
      if (_titleOpacity != 0.0) {
        setState(() {
          _titleOpacity = 0.0;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_updateTitleOpacity);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps(String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  Future<void> _openPhoneApp(String phoneNumber) async {
    // Remove spaces and format for tel: URL
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s-]'), '');
    final url = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch phone app';
    }
  }

  Future<void> _openInstagram() async {
    final url = Uri.parse(
      'https://www.instagram.com/harmoonya.massagee?igsh=MXBqaW43dThjMWVybA==',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Instagram';
    }
  }

  Future<void> _openSnapchat() async {
    final url = Uri.parse(
      'https://www.snapchat.com/@harmoonya?share_id=rcal8RlIbZE&locale=fr-FR',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Snapchat';
    }
  }

  Widget _buildAtHouseCard(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.primary,
                size: isSmallScreen ? 20 : 28,
              ),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  'Massage à domicile disponible',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 20,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Profitez de nos massages dans le confort de votre domicile.\n'
            'Frais de déplacement :',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: isSmallScreen ? 14 : 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: isSmallScreen
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Secteur Illkirch-Graffenstaden : 5€',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: isSmallScreen
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Hors secteur Illkirch-Graffenstaden : 10€',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required bool isAddress,
  }) {
    return InkWell(
      onTap: () async {
        try {
          if (isAddress) {
            await _openGoogleMaps(content);
          } else {
            await _openPhoneApp(content);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Impossible d\'ouvrir ${isAddress ? 'Google Maps' : 'l\'application téléphone'}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.secondary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              content,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddress(BuildContext context) {
    return SelectableText(
      '1 A rue de la poste 67400 ILLKIRCH GRAFFENSTADEN',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
    );
  }

  Widget _buildPhoneNumber(BuildContext context) {
    return SelectableText(
      '06 26 14 25 89',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.9)),
    );
  }

  void _showReviewForm(BuildContext context, bool isSmallScreen) {
    if (isSmallScreen) {
      // Open in a bottom sheet for small screens
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetContext) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: const Text('Laisser un avis'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(bottomSheetContext).pop(),
                      tooltip: 'Fermer',
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: ReviewForm(isSmallScreen: isSmallScreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Open in a dialog for larger screens
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Laisser un avis',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ReviewForm(isSmallScreen: isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showReviews(BuildContext context, bool isSmallScreen) {
    if (isSmallScreen) {
      // Open in a new page for small screens
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (pageContext) => Scaffold(
            appBar: AppBar(title: const Text('Tous les avis')),
            body: const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ReviewsList(isSmallScreen: true),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showReviewForm(pageContext, isSmallScreen),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un avis'),
            ),
          ),
        ),
      ).then((_) {
        // Refresh reviews when returning from review form
        // The stream will automatically update
      });
    } else {
      // Open in a dialog for larger screens
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          child: SizedBox(
            width: 800,
            height: 600,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tous les avis',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add),
                            tooltip: 'Ajouter un avis',
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              _showReviewForm(context, isSmallScreen);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: ReviewsList(isSmallScreen: false),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStarRating(
    BuildContext context,
    double rating,
    int reviewCount,
    bool isSmallScreen,
  ) {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return InkWell(
      onTap: () => _showReviews(context, isSmallScreen),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Full stars
            ...List.generate(fullStars, (index) {
              return Icon(
                Icons.star,
                color: Colors.amber,
                size: isSmallScreen ? 20 : 24,
              );
            }),
            // Half star
            if (hasHalfStar)
              Icon(
                Icons.star_half,
                color: Colors.amber,
                size: isSmallScreen ? 20 : 24,
              ),
            // Empty stars
            ...List.generate(emptyStars, (index) {
              return Icon(
                Icons.star_border,
                color: Colors.amber.withValues(alpha: 0.5),
                size: isSmallScreen ? 20 : 24,
              );
            }),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Text(
              '($reviewCount)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSection(GlobalKey key) {
    // Close drawer first
    Navigator.of(context).pop();
    // Then scroll to section
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToSection(key);
    });
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Harmonya',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Massage & Bien-être',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: () => _navigateToSection(_aboutKey),
          ),
          ListTile(
            leading: const Icon(Icons.spa),
            title: const Text('Nos services'),
            onTap: () => _navigateToSection(_servicesKey),
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('Bon cadeau'),
            onTap: () => _navigateToSection(_giftVoucherKey),
          ),
          ListTile(
            leading: const Icon(Icons.contact_mail),
            title: const Text('Contactez-nous'),
            onTap: () => _navigateToSection(_contactKey),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Témoignages'),
            onTap: () => _navigateToSection(_reviewKey),
          ),
          // Administration link (only when logged in)
          if (FirebaseAuth.instance.currentUser != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Administration'),
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelPage(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Fermer'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isSmallScreen =
        screenWidth < 600; // Use same threshold as other components
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Show loader while data is loading
    if (_isLoadingData) {
      return Scaffold(
        key: _scaffoldKey,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: isSmallScreen ? _buildDrawer(context) : null,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Section as SliverAppBar
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 500,
                pinned: isSmallScreen, // Pin on small screens
                floating: false,
                snap: false,
                backgroundColor: Theme.of(context).colorScheme.primary,
                toolbarHeight: kToolbarHeight,
                collapsedHeight: kToolbarHeight,
                forceElevated: false,
                actions: [
                  if (screenWidth < 600)
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                      tooltip: 'Menu',
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const <StretchMode>[
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                    StretchMode.fadeTitle,
                  ],
                  background: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          screenWidth > 1000
                              ? 'assets/cover_largescreen.png'
                              : 'assets/cover_smallscreen.png',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.spa,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            SizedBox(height: 32),
                            Text(
                              'Harmonya',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 48 : 72,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                            ),
                            SizedBox(height: 12),
                            // Average Rating Stars
                            if (_averageRatingData != null)
                              Builder(
                                builder: (context) {
                                  final averageRating =
                                      _averageRatingData!['rating']
                                          as double? ??
                                      0.0;
                                  final reviewCount =
                                      _averageRatingData!['count'] as int? ?? 0;

                                  if (averageRating == 0.0 ||
                                      reviewCount == 0) {
                                    return const SizedBox.shrink();
                                  }

                                  return _buildStarRating(
                                    context,
                                    averageRating,
                                    reviewCount,
                                    isSmallScreen,
                                  );
                                },
                              ),
                            SizedBox(height: 16),
                            Container(
                              width: 100,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Massage & Bien-être',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 24 : 32,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1,
                                  ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 16 : 32,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.female,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Réservé aux femmes',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
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
              ),
              // Tab Bar (only on big screens)
              if (!isSmallScreen)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.primary,
                      labelStyle: Theme.of(context).textTheme.bodyLarge,
                      unselectedLabelStyle: Theme.of(
                        context,
                      ).textTheme.bodyLarge,
                      indicator: const BoxDecoration(),
                      dividerColor: Colors.transparent,
                      tabs: [
                        const Tab(text: 'À propos'),
                        const Tab(text: 'Nos services'),
                        const Tab(text: 'Bon cadeau'),
                        const Tab(text: 'Contactez-nous'),
                        const Tab(text: 'Témoignages'),
                        if (isLoggedIn) const Tab(text: 'Administration'),
                      ],
                      onTap: (index) {
                        // Handle administration tab
                        if (isLoggedIn && index == 5) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminPanelPage(),
                            ),
                            (route) => false,
                          );
                          return;
                        }

                        // Handle regular tabs
                        GlobalKey? targetKey;
                        switch (index) {
                          case 0:
                            targetKey = _aboutKey;
                            break;
                          case 1:
                            targetKey = _servicesKey;
                            break;
                          case 2:
                            targetKey = _giftVoucherKey;
                            break;
                          case 3:
                            targetKey = _contactKey;
                            break;
                          case 4:
                            targetKey = _reviewKey;
                            break;
                        }
                        if (targetKey != null) {
                          _scrollToSection(targetKey);
                        }
                      },
                    ),
                  ),
                ),

              // About Section
              SliverToBoxAdapter(
                key: _aboutKey,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'À PROPOS',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 22 : 32),
                      Text(
                        'L’harmonie au quotidien',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontSize: isSmallScreen ? 28 : 42),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 22 : 32),
                      SizedBox(
                        width: 900,
                        child: Text(
                          'Nous proposons une gamme de massages et de soins spécialisés, conçus pour répondre à vos besoins individuels. Découvrez nos services de massage bien-être, drainage lymphatique et madérothérapie, chacun offrant des bienfaits uniques pour votre corps et votre esprit.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontSize: 18,
                                height: 1.8,
                                color: const Color(0xFF5A5A5A),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 64),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;

                          if (maxWidth > 800) {
                            // Use Row with IntrinsicHeight for larger screens to ensure same height
                            return Column(
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 350,
                                        height: 200,
                                        child: _buildContactCard(
                                          context,
                                          icon: Icons.location_on,
                                          title: 'Adresse',
                                          content:
                                              '1 A rue de la poste\n67400 ILLKIRCH GRAFFENSTADEN',
                                          isAddress: true,
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                      SizedBox(
                                        width: 350,
                                        height: 200,
                                        child: _buildContactCard(
                                          context,
                                          icon: Icons.phone,
                                          title: 'Téléphone',
                                          content: '06 26 14 25 89',
                                          isAddress: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        try {
                                          await _openSnapchat();
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Impossible d\'ouvrir Snapchat',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/snapchat-logo.png',
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () async {
                                        try {
                                          await _openInstagram();
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Impossible d\'ouvrir Instagram',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/instagram-logo.png',
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: 748,
                                  child: _buildAtHouseCard(
                                    context,
                                    isSmallScreen,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Use Column for smaller screens
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildContactCard(
                                        context,
                                        icon: Icons.location_on,
                                        title: 'Adresse',
                                        content:
                                            '1 A rue de la poste\n67400 ILLKIRCH GRAFFENSTADEN',
                                        isAddress: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildContactCard(
                                            context,
                                            icon: Icons.phone,
                                            title: 'Téléphone',
                                            content: '06 26 14 25 89',
                                            isAddress: false,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            try {
                                              await _openSnapchat();
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Impossible d\'ouvrir Snapchat',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Image.asset(
                                              'assets/snapchat-logo.png',
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        InkWell(
                                          onTap: () async {
                                            try {
                                              await _openInstagram();
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      'Impossible d\'ouvrir Instagram',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8.0),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Image.asset(
                                              'assets/instagram-logo.png',
                                              width: 32,
                                              height: 32,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildAtHouseCard(context, isSmallScreen),
                              ],
                            );
                          }
                        },
                      ),
                      SizedBox(height: isSmallScreen ? 28 : 56),
                    ],
                  ),
                ),
              ),

              // Massage Types Section
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'NOS SERVICES',
                          key: _servicesKey,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 28 : 56),
                      SizedBox(
                        width: 1200,
                        child: _massages == null || _massages!.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'Aucun massage disponible pour le moment',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ServicesCard(
                                isSmallScreen: isSmallScreen,
                                title: 'Nos Massages',
                                services: _massages!,
                                isTreatment: false,
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Treatments Section (Soins)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 1200,
                        child: _treatments == null || _treatments!.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: Text(
                                    'Aucun soin disponible pour le moment',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ServicesCard(
                                isSmallScreen: isSmallScreen,
                                title: 'Nos Soins',
                                services: _treatments!,
                                isTreatment: true,
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // About Hélène Section
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'NOTRE PRATICIENNE',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          final isLargeScreen = maxWidth > 800;

                          return SizedBox(
                            width: isLargeScreen ? 900 : double.infinity,
                            child: isLargeScreen
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Photo
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'assets/helene.jpg',
                                          width: 300,
                                          height: 400,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hélène Chatelard',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displaySmall
                                                  ?.copyWith(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer
                                                    .withValues(alpha: 0.3),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Praticien en Drainage Lymphatique',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Text(
                                              'Formation',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Magic Hands - 2025',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Madérothérapie Drainage Lymphatique classique (vodder)\nDrainage post-opératoire',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    height: 1.6,
                                                    color: const Color(
                                                      0xFF5A5A5A,
                                                    ),
                                                  ),
                                            ),
                                            const SizedBox(height: 32),
                                            Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.format_quote,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    size: 32,
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Text(
                                                      '"Chaque femme porte en elle une énergie unique. Mon rôle est de la libérer."',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.copyWith(
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            height: 1.6,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      // Photo
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          'assets/helene.jpg',
                                          width: double.infinity,
                                          height: 300,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      // Info
                                      Text(
                                        'Hélène Chatelard',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displaySmall
                                            ?.copyWith(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Praticien en Drainage Lymphatique',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Formation',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Magic Hands - 2025',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Madérothérapie Drainage Lymphatique classique (vodder)\nDrainage post-opératoire',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              height: 1.6,
                                              color: const Color(0xFF5A5A5A),
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 32),
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.format_quote,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '"Chaque femme porte en elle une énergie unique. Mon rôle est de la libérer."',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.6,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Gift Voucher Section
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BON CADEAU',
                          key: _giftVoucherKey,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 32),
                      SizedBox(
                        width: 900,
                        child: GiftVoucherForm(isSmallScreen: isSmallScreen),
                      ),
                    ],
                  ),
                ),
              ),

              // Contact Section
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'CONTACTEZ-NOUS',
                          key: _contactKey,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 32),
                      SizedBox(
                        width: isSmallScreen ? double.infinity : 600,
                        child: ContactForm(isSmallScreen: isSmallScreen),
                      ),
                    ],
                  ),
                ),
              ),

              // Review Form Section
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'VOTRE AVIS',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(
                        width: 900,
                        child: ReviewForm(isSmallScreen: isSmallScreen),
                      ),
                    ],
                  ),
                ),
              ),

              // Reviews Section
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 40 : 80,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'TÉMOIGNAGES',
                          key: _reviewKey,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 32),
                      SizedBox(
                        width: 1200,
                        child: ReviewSection(isSmallScreen: isSmallScreen),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: isSmallScreen ? 16 : 32,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.spa,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Harmonya',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      !isSmallScreen
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildAddress(context),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                _buildPhoneNumber(context),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(child: _buildAddress(context)),
                                  ],
                                ),
                                SizedBox(height: 16),
                                _buildPhoneNumber(context),
                              ],
                            ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      // Social Media Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () async {
                              try {
                                await _openSnapchat();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Impossible d\'ouvrir Snapchat',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/snapchat-logo.png',
                                width: isSmallScreen ? 32 : 36,
                                height: isSmallScreen ? 32 : 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 16 : 24),
                          InkWell(
                            onTap: () async {
                              try {
                                await _openInstagram();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Impossible d\'ouvrir Instagram',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.asset(
                                'assets/instagram-logo.png',
                                width: isSmallScreen ? 32 : 36,
                                height: isSmallScreen ? 32 : 36,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 32),
                      TextButton.icon(
                        onPressed: () {
                          final firebaseUser =
                              FirebaseAuth.instance.currentUser;
                          firebaseUser?.uid == null
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminLoginPage(),
                                  ),
                                )
                              : Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AdminPanelPage(),
                                  ),
                                  (route) =>
                                      false, // Clear all routes and go to AdminPanelPage
                                );
                        },
                        icon: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        label: Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '© ${DateTime.now().year} Harmonya. Tous droits réservés.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (isSmallScreen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12.0,
              left: 16.0,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _titleOpacity,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Harmonya',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Delegate for TabBar in SliverPersistentHeader
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
