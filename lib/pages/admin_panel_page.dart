import 'package:flutter/material.dart';
import '../widgets/admin_booking_list.dart';
import '../widgets/admin_booking_calendar.dart';
import '../widgets/admin_review_list.dart';
import '../widgets/customers.dart';
import '../widgets/admin_voucher_list.dart';
import '../widgets/admin_services.dart';
import '../widgets/admin_contact_messages.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'landing_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = AuthService();
  final _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      // Pop back to landing page after logout
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau d\'administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate to landing page, but allow coming back
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LandingPage()),
              );
            },
            tooltip: 'Accueil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Déconnexion',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(isSmallScreen ? 48 : 72),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable:
                true, // Always scrollable to ensure all tabs are accessible
            tabAlignment: TabAlignment.start,
            labelStyle: TextStyle(fontSize: isSmallScreen ? 11 : 14),
            tabs: [
              Tab(
                icon: const Icon(Icons.calendar_today),
                text: isSmallScreen ? null : 'Calendrier',
                iconMargin: isSmallScreen
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 4),
              ),
              StreamBuilder(
                stream: _firebaseService.getBookings(),
                builder: (context, snapshot) {
                  int pendingCount = 0;
                  if (snapshot.hasData) {
                    pendingCount = snapshot.data!
                        .where((booking) => booking.status == 'en_attente')
                        .length;
                  }
                  return Tab(
                    icon: Badge(
                      isLabelVisible: pendingCount > 0,
                      label: Text('$pendingCount'),
                      child: const Icon(Icons.book_online),
                    ),
                    text: isSmallScreen ? null : 'Réservations',
                    iconMargin: isSmallScreen
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(bottom: 4),
                  );
                },
              ),
              StreamBuilder(
                stream: _firebaseService.getPendingReviews(),
                builder: (context, snapshot) {
                  int pendingCount = 0;
                  if (snapshot.hasData) {
                    pendingCount = snapshot.data!.length;
                  }
                  return Tab(
                    icon: Badge(
                      isLabelVisible: pendingCount > 0,
                      label: Text('$pendingCount'),
                      child: const Icon(Icons.rate_review),
                    ),
                    text: isSmallScreen ? null : 'Avis',
                    iconMargin: isSmallScreen
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(bottom: 4),
                  );
                },
              ),
              Tab(
                icon: const Icon(Icons.people),
                text: isSmallScreen ? null : 'Clients',
                iconMargin: isSmallScreen
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: const Icon(Icons.card_giftcard),
                text: isSmallScreen ? null : 'Cadeaux',
                iconMargin: isSmallScreen
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 4),
              ),
              Tab(
                icon: const Icon(Icons.spa),
                text: isSmallScreen ? null : 'Services',
                iconMargin: isSmallScreen
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 4),
              ),
              StreamBuilder(
                stream: _firebaseService.getContactMessages(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!
                        .where((message) =>
                            (message['read'] as bool? ?? false) == false)
                        .length;
                  }
                  return Tab(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0,
                      label: Text('$unreadCount'),
                      child: const Icon(Icons.message),
                    ),
                    text: isSmallScreen ? null : 'Messages',
                    iconMargin: isSmallScreen
                        ? EdgeInsets.zero
                        : const EdgeInsets.only(bottom: 4),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: TabBarView(
          controller: _tabController,
          children: const [
            AdminBookingCalendar(),
            AdminBookingList(),
            AdminReviewList(),
            Customers(),
            AdminVoucherList(),
            AdminServices(),
            AdminContactMessages(),
          ],
        ),
      ),
    );
  }
}
