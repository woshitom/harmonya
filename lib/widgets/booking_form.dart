import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/massage.dart';
import '../models/closed_day.dart';
import '../services/firebase_service.dart';

class BookingForm extends StatefulWidget {
  final String? initialStatus;
  final bool isAdmin;
  final bool isSmallScreen;
  final bool showInDialog;
  final VoidCallback? onSuccess;
  final String? initialServiceType; // 'massage' or 'soins'
  final String? initialSelectedService; // Format: "serviceId_duration"

  const BookingForm({
    super.key,
    this.initialStatus,
    this.isAdmin = false,
    required this.isSmallScreen,
    this.showInDialog = false,
    this.onSuccess,
    this.initialServiceType,
    this.initialSelectedService,
  });

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _homeAddressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _serviceType; // 'massage' or 'soins'
  String?
  _selectedMassageType; // Format: "massageId_duration" (e.g., "cocooning_60")
  bool _isAtHome = false;

  List<Massage> _massages = [];
  List<Massage> _treatments = [];
  List<ClosedDay> _closedDays = [];
  bool _isLoadingMassages = true;
  final _firebaseService = FirebaseService();

  /// Get duration in minutes for a given massage type ID
  /// Format: "massageId_duration" (e.g., "cocooning_60", "evasion_90")
  int _getDurationForMassageType(String? massageTypeId) {
    if (massageTypeId == null) return 60; // Default to 60 minutes

    // Extract duration from format "massageId_duration"
    final parts = massageTypeId.split('_');
    if (parts.length >= 2) {
      final durationStr = parts.last;
      final duration = int.tryParse(durationStr);
      if (duration != null) {
        return duration;
      }
    }

    // Fallback: try to find in services list (massages or treatments)
    final allServices = [..._massages, ..._treatments];
    for (final service in allServices) {
      if (massageTypeId.startsWith(service.id)) {
        // Find matching price option
        for (final price in service.prices) {
          if (service.getMassageOptionId(price.duration) == massageTypeId) {
            return price.duration;
          }
        }
      }
    }

    return 60; // Default to 60 minutes
  }

  /// Get all service options (each service can have multiple duration/price options)
  List<Map<String, dynamic>> _getServiceOptions() {
    final List<Map<String, dynamic>> options = [];
    
    // Use the appropriate list based on selected service type
    final services = _serviceType == 'soins' ? _treatments : _massages;

    for (final service in services) {
      for (final price in service.prices) {
        options.add({
          'id': service.getMassageOptionId(price.duration),
          'serviceId': service.id,
          'name': service.name,
          'price': price.price,
          'duration': price.duration,
        });
      }
    }

    // Sort by service name, then by duration
    options.sort((a, b) {
      final nameCompare = (a['name'] as String).compareTo(b['name'] as String);
      if (nameCompare != 0) return nameCompare;
      return (a['duration'] as int).compareTo(b['duration'] as int);
    });

    return options;
  }

  bool _isSubmitting = false;

  Future<void> _loadMassages() async {
    try {
      final results = await Future.wait([
        _firebaseService.getMassagesOnce(),
        _firebaseService.getTreatmentsOnce(),
        _firebaseService.getClosedDaysOnce(),
      ]);
      
      if (mounted) {
        setState(() {
          _massages = results[0] as List<Massage>;
          _treatments = results[1] as List<Massage>;
          _closedDays = results[2] as List<ClosedDay>;
          _isLoadingMassages = false;
          // Ensure initial selection is set after services are loaded
          if (widget.initialSelectedService != null) {
            _selectedMassageType = widget.initialSelectedService;
          }
        });
      }
    } catch (e) {
      print('Error loading services: $e');
      if (mounted) {
        setState(() {
          _isLoadingMassages = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialServiceType ?? 'massage';
    _selectedMassageType = widget.initialSelectedService;
    _loadMassages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    // When form is in dialog, use root navigator to show date picker above dialog
    BuildContext datePickerContext = context;
    if (widget.showInDialog) {
      // Get the root navigator's overlay context
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      datePickerContext = rootNavigator.overlay?.context ?? context;
    }

    // Ensure initialDate satisfies the selectableDayPredicate
    DateTime initialDate = _selectedDate ?? DateTime.now();
    // If selected date is a Sunday, use today or next valid date
    if (initialDate.weekday == DateTime.sunday) {
      initialDate = DateTime.now();
      // If today is Sunday, find the next Monday
      if (initialDate.weekday == DateTime.sunday) {
        initialDate = initialDate.add(const Duration(days: 1));
      }
    }

    // Get closed days dates (only date part, no time)
    final closedDates = _closedDays.map((closedDay) {
      return DateTime(
        closedDay.date.year,
        closedDay.date.month,
        closedDay.date.day,
      );
    }).toSet();

    final DateTime? picked = await showDatePicker(
      context: datePickerContext,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Disable Sundays (weekday 7 in Dart, where Monday is 1)
        if (date.weekday == DateTime.sunday) {
          return false;
        }
        
        // Disable closed days
        final dateOnly = DateTime(date.year, date.month, date.day);
        if (closedDates.contains(dateOnly)) {
          return false;
        }
        
        return true;
      },
      // Force calendar mode only - disables manual date input
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      final previousTime = _selectedTime;
      setState(() {
        _selectedDate = picked;
        // Clear selected time if it's no longer valid for the new date
        if (previousTime != null) {
          final isSaturday = picked.weekday == DateTime.saturday;
          final currentHour = previousTime.hour;
          final isValidTime = isSaturday
              ? (currentHour >= 10 && currentHour <= 20)
              : (currentHour >= 17 && currentHour <= 22);

          if (!isValidTime) {
            _selectedTime = null;
          }
        }
      });
    }
  }

  List<String> _getAvailableTimeSlots() {
    if (_selectedDate == null) {
      return [];
    }

    // Check if selected date is Saturday (weekday 6)
    final isSaturday = _selectedDate!.weekday == DateTime.saturday;

    if (isSaturday) {
      // Saturday: 10:00 to 20:00 (every hour)
      return List.generate(11, (index) {
        final hour = 10 + index;
        return '${hour.toString().padLeft(2, '0')}:00';
      });
    } else {
      // Monday to Friday: 17:00 to 22:00 (every hour)
      return List.generate(6, (index) {
        final hour = 17 + index;
        return '${hour.toString().padLeft(2, '0')}:00';
      });
    }
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner une date'),
        ),
      );
      return;
    }

    // Fetch bookings for the selected date
    final bookings = await _firebaseService.getBookingsForDate(_selectedDate!);

    // Get active bookings (only confirmed and pending bookings, not cancelled)
    final activeBookings = bookings
        .where(
          (booking) => booking.status != 'cancelled' && booking.time.isNotEmpty,
        )
        .toList();

    final availableSlots = _getAvailableTimeSlots();
    final isSaturday = _selectedDate!.weekday == DateTime.saturday;

    // Helper function to check if a time slot overlaps with any booking
    bool _isSlotBlocked(String timeSlot, List<Booking> bookings) {
      final slotParts = timeSlot.split(':');
      final slotHour = int.parse(slotParts[0]);
      final slotMinute = int.parse(slotParts[1]);
      final slotTimeInMinutes = slotHour * 60 + slotMinute;

      // Get the duration of the selected massage type (if any)
      final selectedDuration = _selectedMassageType != null
          ? _getDurationForMassageType(_selectedMassageType)
          : 60; // Default to 60 minutes if no massage type selected

      for (final booking in bookings) {
        final bookingParts = booking.time.split(':');
        final bookingHour = int.parse(bookingParts[0]);
        final bookingMinute = int.parse(bookingParts[1]);
        final bookingStartInMinutes = bookingHour * 60 + bookingMinute;
        final bookingEndInMinutes = bookingStartInMinutes + booking.duration;

        // Check if the slot overlaps with the booking
        // Slot overlaps if:
        // 1. Slot starts during the booking (slotStart >= bookingStart && slotStart < bookingEnd)
        // 2. Slot ends during the booking (slotEnd > bookingStart && slotEnd <= bookingEnd)
        // 3. Slot completely contains the booking (slotStart <= bookingStart && slotEnd >= bookingEnd)
        final slotEndInMinutes = slotTimeInMinutes + selectedDuration;

        if (slotTimeInMinutes < bookingEndInMinutes &&
            slotEndInMinutes > bookingStartInMinutes) {
          return true; // Overlaps
        }
      }
      return false; // No overlap
    }

    // When form is in dialog, use root navigator to show time picker above dialog
    BuildContext timePickerContext = context;
    if (widget.showInDialog) {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      timePickerContext = rootNavigator.overlay?.context ?? context;
    }

    await showDialog(
      context: timePickerContext,
      builder: (BuildContext context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isSaturday
                    ? 'Sélectionner une heure (Samedi)'
                    : 'Sélectionner une heure',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: availableSlots.length,
                  itemBuilder: (context, index) {
                    final timeSlot = availableSlots[index];
                    final isSelected =
                        _selectedTime != null &&
                        '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' ==
                            timeSlot;
                    final isBooked = _isSlotBlocked(timeSlot, activeBookings);

                    return ElevatedButton(
                      onPressed: isBooked
                          ? null
                          : () {
                              final parts = timeSlot.split(':');
                              setState(() {
                                _selectedTime = TimeOfDay(
                                  hour: int.parse(parts[0]),
                                  minute: int.parse(parts[1]),
                                );
                              });
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBooked
                            ? Colors.grey[300]
                            : isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        foregroundColor: isBooked
                            ? Colors.grey[600]
                            : isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: isBooked
                              ? Colors.grey[400]!
                              : Theme.of(context).colorScheme.primary,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            timeSlot,
                            style: TextStyle(
                              fontSize: 16,
                              decoration: isBooked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (isBooked)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une heure')),
      );
      return;
    }

    if (_serviceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de service (Massage ou Soins)'),
        ),
      );
      return;
    }

    if (_selectedMassageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_serviceType == 'soins'
              ? 'Veuillez sélectionner un type de soin'
              : 'Veuillez sélectionner un type de massage'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Find the service name from the selected option
      final serviceOptions = _getServiceOptions();
      final selectedOption = serviceOptions.firstWhere(
        (option) => option['id'] == _selectedMassageType,
        orElse: () => {'name': ''},
      );
      final serviceName = selectedOption['name'] as String? ?? '';
      
      final booking = Booking(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        date: _selectedDate!,
        time:
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        massageType: _selectedMassageType!,
        serviceType: _serviceType,
        serviceName: serviceName.isNotEmpty ? serviceName : null,
        duration: _getDurationForMassageType(_selectedMassageType),
        notes: _notesController.text.trim(),
        isAtHome: _isAtHome,
        homeAddress: _isAtHome ? _homeAddressController.text.trim() : '',
        status: widget.initialStatus ?? 'en_attente',
        createdAt: DateTime.now(),
      );

      await _firebaseService.createBooking(booking);

      if (mounted) {
        if (widget.showInDialog) {
          // For admin dialog mode, show snackbar and close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.initialStatus == 'confirmed'
                    ? 'Réservation créée et confirmée avec succès'
                    : 'Réservation créée avec succès',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          }
        } else {
          // For customer mode, show success dialog
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Réservation envoyée !',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      'Votre demande de réservation a été envoyée avec succès. Nous vous contacterons bientôt par email ou téléphone pour confirmer votre rendez-vous.',
                      style: TextStyle(fontSize: 16),
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          // Reset form
          _formKey.currentState!.reset();
          _nameController.clear();
          _emailController.clear();
          _phoneController.clear();
          _notesController.clear();
          _homeAddressController.clear();
          setState(() {
            _selectedDate = null;
            _selectedTime = null;
            _selectedMassageType = null;
            _isAtHome = false;
          });
        }
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
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget _selectDateButton = OutlinedButton.icon(
      onPressed: _selectDate,
      icon: const Icon(Icons.calendar_today),
      label: Text(
        _selectedDate == null
            ? 'Sélectionner une date'
            : DateFormat('dd/MM/yyyy', 'fr').format(_selectedDate!),
      ),
    );

    final Widget _selectTimeButton = OutlinedButton.icon(
      onPressed: _selectTime,
      icon: const Icon(Icons.access_time),
      label: Text(
        _selectedTime == null
            ? 'Sélectionner une heure'
            : _selectedTime!.format(context),
      ),
    );

    final content = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: widget.showInDialog ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (!widget.isAdmin)
            Text(
              widget.showInDialog
                  ? 'Ajouter une réservation'
                  : 'Réserver votre massage',
              style: widget.showInDialog
                  ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: widget.isSmallScreen ? 20 : 24,
                    )
                  : Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: widget.isSmallScreen ? 24 : 32,
                    ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 8),
          if (!widget.showInDialog)
            if (!widget.isAdmin)
              Text(
                'Remplissez le formulaire ci-dessous pour réserver votre séance',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
          SizedBox(height: widget.isSmallScreen ? 16 : 32),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet *',
              prefixIcon: Icon(Icons.person),
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email *',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Téléphone *',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre numéro de téléphone';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Service Type Selection (Massage or Soins)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'massage',
                label: Text('Massage'),
                icon: Icon(Icons.spa),
              ),
              ButtonSegment(
                value: 'soins',
                label: Text('Soins'),
                icon: Icon(Icons.healing),
              ),
            ],
            selected: {_serviceType ?? 'massage'},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _serviceType = newSelection.first;
                _selectedMassageType = null; // Reset selection when type changes
              });
            },
          ),
          const SizedBox(height: 16),
          _isLoadingMassages
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : (_serviceType == 'soins' ? _treatments : _massages).isEmpty
              ? Text(
                  'Aucun ${_serviceType == 'soins' ? 'soin' : 'massage'} disponible pour le moment',
                  style: const TextStyle(color: Colors.red),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedMassageType,
                  decoration: InputDecoration(
                    labelText: _serviceType == 'soins' 
                        ? 'Type de soin *' 
                        : 'Type de massage *',
                    prefixIcon: const Icon(Icons.spa),
                  ),
                  items: _getServiceOptions().map((option) {
                    return DropdownMenuItem(
                      value: option['id'] as String,
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          '${option['name']} - ${(option['price'] as double).toInt()}€ (${option['duration']} min)',
                          softWrap: true,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMassageType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return _serviceType == 'soins'
                          ? 'Veuillez sélectionner un type de soin'
                          : 'Veuillez sélectionner un type de massage';
                    }
                    return null;
                  },
                  isExpanded: true,
                  menuMaxHeight: 400,
                  selectedItemBuilder: (BuildContext context) {
                    // This controls what's shown in the button itself (can be truncated)
                    return _getServiceOptions().map((option) {
                      return Text(
                        '${option['name']} - ${(option['price'] as double).toInt()}€ (${option['duration']} min)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      );
                    }).toList();
                  },
                ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Massage à domicile'),
            subtitle: const Text(
              'Frais de déplacement : 5€ (secteur Illkirch-Graffenstaden) / 10€ (hors secteur Illkirch-Graffenstaden)',
            ),
            value: _isAtHome,
            onChanged: (value) {
              setState(() {
                _isAtHome = value ?? false;
                if (!_isAtHome) {
                  _homeAddressController.clear();
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          if (_isAtHome) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _homeAddressController,
              decoration: const InputDecoration(
                labelText: 'Adresse complète *',
                hintText: 'Rue, ville, code postal',
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (_isAtHome && (value == null || value.trim().isEmpty)) {
                  return 'Veuillez entrer votre adresse';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Horaires d\'ouverture',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lundi - Vendredi : 17h00 - 22h00\n'
                  'Samedi : 10h00 - 20h00\n'
                  'Dimanche : Fermé',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!widget.isSmallScreen)
            Row(
              children: [
                Expanded(child: _selectDateButton),
                const SizedBox(width: 16),
                Expanded(child: _selectTimeButton),
              ],
            ),
          if (widget.isSmallScreen)
            Column(
              children: [
                _selectDateButton,
                const SizedBox(height: 16),
                _selectTimeButton,
              ],
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Demandes spéciales ou notes',
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isSubmitting) {
                _submitBooking();
              }
            },
          ),
          const SizedBox(height: 24),
          if (widget.showInDialog)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Créer'),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer la réservation'),
            ),
        ],
      ),
    );

    if (widget.showInDialog) {
      return Material(
        type: MaterialType.canvas,
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
    );
  }
}
