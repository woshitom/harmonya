import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/booking.dart';
import '../models/closed_day.dart';
import '../services/firebase_service.dart';
import 'service_name_display.dart';
import 'admin_closed_days.dart';

class AdminBookingCalendar extends StatelessWidget {
  const AdminBookingCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<Booking>>(
      stream: firebaseService.getBookings(),
      builder: (context, bookingsSnapshot) {
        return StreamBuilder<List<ClosedDay>>(
          stream: firebaseService.getClosedDays(),
          builder: (context, closedDaysSnapshot) {
            if (bookingsSnapshot.connectionState == ConnectionState.waiting ||
                closedDaysSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (bookingsSnapshot.hasError) {
              return Center(child: Text('Erreur: ${bookingsSnapshot.error}'));
            }

            final bookings = bookingsSnapshot.data ?? [];
            final closedDays = closedDaysSnapshot.data ?? [];

            // Group bookings by date
            final Map<DateTime, List<Booking>> bookingsByDate = {};
            for (final booking in bookings) {
              final date = DateTime(
                booking.date.year,
                booking.date.month,
                booking.date.day,
              );
              bookingsByDate.putIfAbsent(date, () => []).add(booking);
            }

            // Group closed days by date
            final Set<DateTime> closedDates = {};
            for (final closedDay in closedDays) {
              final date = DateTime(
                closedDay.date.year,
                closedDay.date.month,
                closedDay.date.day,
              );
              closedDates.add(date);
            }

            return _CalendarWidget(
              bookingsByDate: bookingsByDate,
              allBookings: bookings,
              closedDates: closedDates,
            );
          },
        );
      },
    );
  }
}

class _CalendarWidget extends StatefulWidget {
  final Map<DateTime, List<Booking>> bookingsByDate;
  final List<Booking> allBookings;
  final Set<DateTime> closedDates;

  const _CalendarWidget({
    required this.bookingsByDate,
    required this.allBookings,
    required this.closedDates,
  });

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return widget.bookingsByDate[date] ?? [];
  }

  bool _isDayClosed(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return widget.closedDates.contains(dateOnly);
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayBookings = _getBookingsForDay(_selectedDay);
    final isSelectedDayClosed = _isDayClosed(_selectedDay);

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            TableCalendar<Booking>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getBookingsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              locale: 'fr_FR',
              headerStyle: HeaderStyle(
                formatButtonVisible:
                    false, // Hide format button to restrict to month view
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 6,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, events) {
                  final dateOnly = DateTime(date.year, date.month, date.day);
                  final isClosed = widget.closedDates.contains(dateOnly);

                  if (isClosed) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                // Ignore format changes - always keep month view
                // Don't update state to prevent format switching
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            const Divider(),
            Expanded(
              child: isSelectedDayClosed
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Jour fermé',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat(
                              'EEEE dd MMMM yyyy',
                              'fr',
                            ).format(_selectedDay),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : selectedDayBookings.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune réservation pour le ${DateFormat('dd MMMM yyyy', 'fr').format(_selectedDay)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: selectedDayBookings.length,
                      itemBuilder: (context, index) {
                        final booking = selectedDayBookings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: _getStatusIcon(booking.status),
                            title: Text(booking.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<Map<String, String>>(
                                  future: getServiceNameAndLabel(booking),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        '${booking.time} - Chargement...',
                                      );
                                    }
                                    if (snapshot.hasData) {
                                      return Text(
                                        '${booking.time} - ${snapshot.data!['name']!}',
                                      );
                                    }
                                    return Text(
                                      '${booking.time} - ${booking.massageType}',
                                    );
                                  },
                                ),
                                if (booking.isAtHome)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.home,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'À domicile',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                Text(
                                  _getStatusLabel(booking.status),
                                  style: TextStyle(
                                    color: _getStatusColor(booking.status),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () {
                                _showBookingDetails(context, booking);
                              },
                            ),
                            onTap: () {
                              _showBookingDetails(context, booking);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
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

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(booking.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', booking.email),
              _buildDetailRow('Téléphone', booking.phone),
              _buildDetailRow(
                'Date',
                DateFormat('dd/MM/yyyy', 'fr').format(booking.date),
              ),
              _buildDetailRow('Heure', booking.time),
              FutureBuilder<Map<String, String>>(
                future: getServiceNameAndLabel(booking),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildDetailRow('Type de massage', 'Chargement...');
                  }
                  if (snapshot.hasData) {
                    return _buildDetailRow(
                      snapshot.data!['label']!,
                      snapshot.data!['name']!,
                    );
                  }
                  return _buildDetailRow(
                    booking.serviceType == 'soins'
                        ? 'Type de soins'
                        : 'Type de massage',
                    booking.massageType,
                  );
                },
              ),
              _buildDetailRow('Statut', _getStatusLabel(booking.status)),
              if (booking.isAtHome) ...[
                _buildDetailRow('Lieu', 'À domicile'),
                if (booking.homeAddress.isNotEmpty)
                  _buildDetailRow('Adresse', booking.homeAddress),
              ] else
                _buildDetailRow('Lieu', 'Sur place'),
              if (booking.notes.isNotEmpty)
                _buildDetailRow('Notes', booking.notes),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
}
