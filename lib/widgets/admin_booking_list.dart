import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';
import 'booking_form.dart';
import 'service_name_display.dart';
import 'admin_closed_days.dart';

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

class AdminBookingList extends StatelessWidget {
  const AdminBookingList({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Stack(
      children: [
        StreamBuilder<List<Booking>>(
          stream: firebaseService.getBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final bookings = snapshot.data ?? [];

            if (bookings.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminClosedDays(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.event_busy),
                          label: const Text('Jours fermés'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Aucune réservation pour le moment'),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminClosedDays(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_busy),
                        label: const Text('Jours fermés'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: ExpansionTile(
                          leading: _getStatusIcon(booking.status),
                          title: Text(booking.name),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy', 'fr').format(booking.date)} à ${booking.time}',
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Email', booking.email),
                                  _buildInfoRow('Téléphone', booking.phone),
                                  FutureBuilder<Map<String, String>>(
                                    future: getServiceNameAndLabel(booking),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return _buildInfoRow(
                                          'Type de massage',
                                          'Chargement...',
                                        );
                                      }
                                      if (snapshot.hasData) {
                                        return _buildInfoRow(
                                          snapshot.data!['label']!,
                                          snapshot.data!['name']!,
                                        );
                                      }
                                      return _buildInfoRow(
                                        booking.serviceType == 'soins'
                                            ? 'Type de soins'
                                            : 'Type de massage',
                                        booking.massageType,
                                      );
                                    },
                                  ),
                                  _buildInfoRow(
                                    'Statut',
                                    _getStatusLabel(booking.status),
                                  ),
                                  if (booking.isAtHome) ...[
                                    _buildInfoRow('Lieu', 'À domicile'),
                                    if (booking.homeAddress.isNotEmpty)
                                      _buildInfoRow(
                                        'Adresse',
                                        booking.homeAddress,
                                      ),
                                  ] else
                                    _buildInfoRow('Lieu', 'Sur place'),
                                  if (booking.notes.isNotEmpty)
                                    _buildInfoRow('Notes', booking.notes),
                                  _buildInfoRow(
                                    'Créé le',
                                    DateFormat(
                                      'dd/MM/yyyy à HH:mm',
                                      'fr',
                                    ).format(booking.createdAt),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (booking.status == 'en_attente')
                                        TextButton.icon(
                                          onPressed: () => _updateStatus(
                                            context,
                                            firebaseService,
                                            booking.id!,
                                            'confirmed',
                                          ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Confirmer'),
                                        ),
                                      if (booking.status != 'cancelled')
                                        TextButton.icon(
                                          onPressed: () => _updateStatus(
                                            context,
                                            firebaseService,
                                            booking.id!,
                                            'cancelled',
                                          ),
                                          icon: const Icon(Icons.cancel),
                                          label: const Text('Annuler'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _deleteBooking(
                                          context,
                                          firebaseService,
                                          booking.id!,
                                        ),
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              bool isSmallScreen = MediaQuery.of(context).size.width < 430;
              !isSmallScreen
                  ? showDialog(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 600,
                            maxHeight: 700,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ajouter une réservation',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.headlineSmall,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: ScrollConfiguration(
                                    behavior: NoScrollbarScrollBehavior(),
                                    child: SingleChildScrollView(
                                      child: BookingForm(
                                        isAdmin: true,
                                        initialStatus: 'confirmed',
                                        showInDialog: true,
                                        isSmallScreen: isSmallScreen,
                                        onSuccess: () =>
                                            Navigator.of(dialogContext).pop(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Ajouter une réservation'),
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          body: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: BookingForm(
                              isAdmin: true,
                              initialStatus: 'confirmed',
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                        ),
                      ),
                    );
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter une réservation'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'cancelled':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.pending, color: Colors.orange);
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    FirebaseService service,
    String id,
    String status,
  ) async {
    try {
      await service.updateBooking(id, {'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusLabel(status)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteBooking(
    BuildContext context,
    FirebaseService service,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette réservation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await service.deleteBooking(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
