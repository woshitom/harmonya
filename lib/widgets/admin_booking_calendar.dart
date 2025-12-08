import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';

class AdminBookingCalendar extends StatelessWidget {
  const AdminBookingCalendar({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<Booking>>(
      stream: firebaseService.getBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final bookings = snapshot.data ?? [];
        
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

        return _CalendarWidget(
          bookingsByDate: bookingsByDate,
          allBookings: bookings,
        );
      },
    );
  }
}

class _CalendarWidget extends StatefulWidget {
  final Map<DateTime, List<Booking>> bookingsByDate;
  final List<Booking> allBookings;

  const _CalendarWidget({
    required this.bookingsByDate,
    required this.allBookings,
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

  @override
  Widget build(BuildContext context) {
    final selectedDayBookings = _getBookingsForDay(_selectedDay);

    return Column(
      children: [
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
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(),
        Expanded(
          child: selectedDayBookings.isEmpty
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
                            Text('${booking.time} - ${booking.massageType}'),
                            if (booking.isAtHome)
                              Row(
                                children: [
                                  Icon(Icons.home, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  const Text('À domicile', style: TextStyle(fontSize: 12)),
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
              _buildDetailRow('Date', DateFormat('dd/MM/yyyy', 'fr').format(booking.date)),
              _buildDetailRow('Heure', booking.time),
              _buildDetailRow('Type de massage', booking.massageType),
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

