import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/closed_day.dart';
import '../services/firebase_service.dart';

class AdminClosedDays extends StatefulWidget {
  const AdminClosedDays({super.key});

  @override
  State<AdminClosedDays> createState() => _AdminClosedDaysState();
}

class _AdminClosedDaysState extends State<AdminClosedDays> {
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  Future<void> _addClosedDay() async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) =>
          _MultiDatePickerDialog(firebaseService: _firebaseService),
    );

    if (result != null &&
        result['dates'] != null &&
        result['dates'].isNotEmpty) {
      final selectedDates = result['dates'] as List<DateTime>;

      setState(() {
        _isLoading = true;
      });

      try {
        // Get existing closed days to check for duplicates
        final closedDays = await _firebaseService.getClosedDaysOnce();
        final existingDates = closedDays.map((day) {
          return DateTime(day.date.year, day.date.month, day.date.day);
        }).toSet();

        int addedCount = 0;
        int skippedCount = 0;

        for (final date in selectedDates) {
          final dateOnly = DateTime(date.year, date.month, date.day);

          // Skip if already closed
          if (existingDates.contains(dateOnly)) {
            skippedCount++;
            continue;
          }

          final closedDay = ClosedDay(date: date);
          await _firebaseService.createClosedDay(closedDay);
          addedCount++;
        }

        if (mounted) {
          String message;
          if (skippedCount > 0) {
            message =
                '$addedCount jour(s) fermé(s) ajouté(s). $skippedCount date(s) déjà fermée(s) ignorée(s).';
          } else {
            message = '$addedCount jour(s) fermé(s) ajouté(s) avec succès';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: skippedCount > 0 ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _deleteClosedDay(ClosedDay closedDay) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le jour fermé'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le ${DateFormat('dd/MM/yyyy', 'fr').format(closedDay.date)} ?',
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
      setState(() {
        _isLoading = true;
      });

      try {
        await _firebaseService.deleteClosedDay(closedDay.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jour fermé supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jours fermés'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<ClosedDay>>(
            stream: _firebaseService.getClosedDays(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final closedDays = snapshot.data ?? [];

              // Filter to show only future dates
              final now = DateTime.now();
              final startOfToday = DateTime(now.year, now.month, now.day);
              final futureClosedDays = closedDays.where((day) {
                final dayDate = DateTime(
                  day.date.year,
                  day.date.month,
                  day.date.day,
                );
                return dayDate.isAfter(startOfToday) ||
                    dayDate.isAtSameMomentAs(startOfToday);
              }).toList();

              if (futureClosedDays.isEmpty) {
                return const Center(child: Text('Aucun jour fermé à venir'));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: futureClosedDays.length,
                itemBuilder: (context, index) {
                  final closedDay = futureClosedDays[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(
                        DateFormat(
                          'EEEE dd MMMM yyyy',
                          'fr',
                        ).format(closedDay.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: closedDay.reason != null
                          ? Text(closedDay.reason!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _isLoading
                            ? null
                            : () => _deleteClosedDay(closedDay),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _isLoading ? null : _addClosedDay,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un jour fermé'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiDatePickerDialog extends StatefulWidget {
  final FirebaseService firebaseService;

  const _MultiDatePickerDialog({required this.firebaseService});

  @override
  State<_MultiDatePickerDialog> createState() => _MultiDatePickerDialogState();
}

class _MultiDatePickerDialogState extends State<_MultiDatePickerDialog> {
  final Set<DateTime> _selectedDates = {};
  DateTime _focusedMonth = DateTime.now();
  List<ClosedDay> _closedDays = [];
  bool _isLoadingClosedDays = true;

  @override
  void initState() {
    super.initState();
    _loadClosedDays();
  }

  Future<void> _loadClosedDays() async {
    try {
      final closedDays = await widget.firebaseService.getClosedDaysOnce();
      if (mounted) {
        setState(() {
          _closedDays = closedDays;
          _isLoadingClosedDays = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClosedDays = false;
        });
      }
    }
  }

  bool _isDateClosed(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _closedDays.any((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate.isAtSameMomentAs(dateOnly);
    });
  }

  bool _isDateSelected(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return _selectedDates.any((selectedDate) {
      final selectedDateOnly = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      return selectedDateOnly.isAtSameMomentAs(dateOnly);
    });
  }

  void _toggleDate(DateTime date) {
    setState(() {
      final dateOnly = DateTime(date.year, date.month, date.day);

      // Check if already selected
      final isCurrentlySelected = _isDateSelected(date);

      if (isCurrentlySelected) {
        // Remove if already selected
        _selectedDates.removeWhere((selectedDate) {
          final selectedDateOnly = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
          );
          return selectedDateOnly.isAtSameMomentAs(dateOnly);
        });
      } else {
        // Add if not selected
        _selectedDates.add(date);
      }
    });
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime.now().add(const Duration(days: 365));

    return TableCalendar(
      firstDay: firstDate,
      lastDay: lastDate,
      focusedDay: _focusedMonth,
      calendarFormat: CalendarFormat.month,
      startingDayOfWeek: StartingDayOfWeek.monday,
      locale: 'fr_FR',
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      selectedDayPredicate: (day) {
        return _isDateSelected(day);
      },
      enabledDayPredicate: (day) {
        final isPast = day.isBefore(firstDate);
        final isSunday = day.weekday == DateTime.sunday;
        final isClosed = _isDateClosed(day);
        return !isPast && !isSunday && !isClosed;
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
        ),
        disabledDecoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        disabledTextStyle: const TextStyle(color: Colors.grey),
        markerDecoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _focusedMonth = focusedDay;
          _toggleDate(selectedDay);
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedMonth = focusedDay;
        });
      },
      eventLoader: (day) {
        if (_isDateClosed(day)) {
          return [day]; // Return a marker for closed days
        }
        return [];
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          if (_isDateClosed(date)) {
            return Positioned(
              bottom: 1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner les jours fermés'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoadingClosedDays
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCalendar(),
                    if (_selectedDates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${_selectedDates.length} date(s) sélectionnée(s)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedDates.isEmpty
              ? null
              : () {
                  Navigator.pop(context, {'dates': _selectedDates.toList()});
                },
          child: Text(
            _selectedDates.isEmpty
                ? 'Sélectionner des dates'
                : 'Ajouter ${_selectedDates.length} date(s)',
          ),
        ),
      ],
    );
  }
}
