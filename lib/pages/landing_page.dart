import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/massage_card.dart';
import '../widgets/booking_form.dart';
import '../widgets/review_section.dart';
import '../widgets/review_form.dart';
import '../widgets/gift_voucher_form.dart';
import 'admin_login_page.dart';
import 'admin_panel_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  Widget _buildAdminButton(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return firebaseUser?.uid != null
        ? IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              // Always try to pop back first (if we came from admin panel via Navigator.push)
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                // If we can't pop, we're at root (AuthWrapper showing LandingPage)
                // Navigate directly to AdminPanelPage - user is already authenticated
                // Use pushAndRemoveUntil to replace current route and clear stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelPage(),
                  ),
                  (route) => false, // Clear all routes and go to AdminPanelPage
                );
              }
            },
            tooltip: 'Panneau d\'administration',
          )
        : const SizedBox.shrink();
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

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 430;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Section as SliverAppBar
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 500,
            pinned: false,
            backgroundColor: Theme.of(context).colorScheme.primary,
            actions: [_buildAdminButton(context)],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
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
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
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
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.female, color: Colors.white, size: 20),
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

          // About Section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 40 : 80,
                horizontal: isSmallScreen ? 16 : 32,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'À PROPOS',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 22 : 32),
                  Text(
                    'Bienvenue chez Harmonya',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: isSmallScreen ? 28 : 42,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 22 : 32),
                  SizedBox(
                    width: 900,
                    child: Text(
                      'Découvrez un havre de paix dédié à votre bien-être. Chez Harmonya, nous vous proposons des massages personnalisés dans une atmosphère apaisante et relaxante.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                            const SizedBox(height: 24),
                            Container(
                              width: 748,
                              child: _buildAtHouseCard(context, isSmallScreen),
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

          // About Hélène Section
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NOTRE PRATICIENNE',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                                color: const Color(0xFF5A5A5A),
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
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        height: 1.6,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
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
                                      borderRadius: BorderRadius.circular(8),
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
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Magic Hands - 2025',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
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
                                      borderRadius: BorderRadius.circular(12),
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'NOS SERVICES',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Nos Massages',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: isSmallScreen ? 28 : 42,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 28 : 56),
                  SizedBox(
                    width: 1200,
                    child: Column(
                      children: [
                        MassageCard(
                          isSmallScreen: isSmallScreen,
                          title: 'Découverte',
                          description:
                              'Inspiré du massage suédois, laissez-vous aller vers un cocon de douceur, avec le massage découverte, une invitation à la sérénité.',
                          zones: 'cervicales, dos, épaule, jambes',
                          price: '45€',
                          duration: '30 min',
                        ),
                        MassageCard(
                          isSmallScreen: isSmallScreen,
                          title: 'Immersion',
                          description:
                              'Laissez-vous porter par la magie du massage sensoriel. Chaque thème choisi réveillera vos sens et vous plongera dans une ambiance propice à un doux voyage, loin du stress:\n\n• Les Îles: cervicales, dos, épaules, abdomen, jambes, pieds\n• L\'Asie: cervicales, dos, épaules, visage, jambes, pieds\n• L\'Orient: cuir chevelu, cervicales, dos, épaules, jambes, pieds\n• L\'Afrique: cervicales, dos, épaules, abdomen, jambes',
                          zones: '',
                          price: '60€',
                          duration: '60 min',
                        ),
                        MassageCard(
                          isSmallScreen: isSmallScreen,
                          title: 'Evasion',
                          description:
                              'Prolongez votre massage immersion, combinant des techniques de réflexologie, pour un lâché prise total.',
                          zones: '',
                          price: '85€',
                          duration: '90 min',
                        ),
                        MassageCard(
                          isSmallScreen: isSmallScreen,
                          title: 'Cocooning',
                          description:
                              'Relâchez les tensions avec le massage aux pierres chaudes alliant chaleur et douceur, pour un moment de pure relaxation.',
                          zones:
                              'cervicales, dos, épaules, visage, jambes, pieds',
                          price: '95€ / 115€',
                          duration: '60 min / 90 min',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Booking Section
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 40 : 80,
                horizontal: isSmallScreen ? 16 : 32,
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'RÉSERVATION',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 900,
                    child: BookingForm(isSmallScreen: isSmallScreen),
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'BON CADEAU',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'VOTRE AVIS',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TÉMOIGNAGES',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                  color: Colors.white.withValues(alpha: 0.5),
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
                  SizedBox(height: isSmallScreen ? 16 : 32),
                  TextButton.icon(
                    onPressed: () {
                      final firebaseUser = FirebaseAuth.instance.currentUser;
                      firebaseUser?.uid == null
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminLoginPage(),
                              ),
                            )
                          : Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminPanelPage(),
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
    );
  }
}
