import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';

class BookingForm extends StatefulWidget {
  final String? initialStatus;
  final bool isAdmin;
  final bool isSmallScreen;
  final bool showInDialog;
  final VoidCallback? onSuccess;

  const BookingForm({
    super.key,
    this.initialStatus,
    this.isAdmin = false,
    required this.isSmallScreen,
    this.showInDialog = false,
    this.onSuccess,
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
  String? _selectedMassageType;
  bool _isAtHome = false;

  final List<Map<String, String>> _massageTypes = [
    {
      'id': 'decouverte',
      'name': 'Découverte',
      'price': '45€',
      'duration': '30 min',
    },
    {
      'id': 'immersion',
      'name': 'Immersion',
      'price': '60€',
      'duration': '60 min',
    },
    {'id': 'evasion', 'name': 'Evasion', 'price': '85€', 'duration': '90 min'},
    {
      'id': 'cocooning_60',
      'name': 'Cocooning',
      'price': '95€',
      'duration': '60 min',
    },
    {
      'id': 'cocooning_90',
      'name': 'Cocooning',
      'price': '115€',
      'duration': '90 min',
    },
  ];

  bool _isSubmitting = false;
  final _firebaseService = FirebaseService();

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

    final DateTime? picked = await showDatePicker(
      context: datePickerContext,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (DateTime date) {
        // Disable Sundays (weekday 7 in Dart, where Monday is 1)
        return date.weekday != DateTime.sunday;
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

    // Get booked time slots (only confirmed and pending bookings, not cancelled)
    final bookedSlots = bookings
        .where(
          (booking) => booking.status != 'cancelled' && booking.time.isNotEmpty,
        )
        .map((booking) => booking.time)
        .toSet();

    final availableSlots = _getAvailableTimeSlots();
    final isSaturday = _selectedDate!.weekday == DateTime.saturday;

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
                    final isBooked = bookedSlots.contains(timeSlot);

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

    if (_selectedMassageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de massage'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final booking = Booking(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        date: _selectedDate!,
        time:
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        massageType: _selectedMassageType!,
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
          DropdownButtonFormField<String>(
            value: _selectedMassageType,
            decoration: const InputDecoration(
              labelText: 'Type de massage *',
              prefixIcon: Icon(Icons.spa),
            ),
            items: _massageTypes.map((type) {
              return DropdownMenuItem(
                value: type['id'],
                child: Text(
                  '${type['name']} - ${type['price']} (${type['duration']})',
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
                return 'Veuillez sélectionner un type de massage';
              }
              return null;
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
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(child: content),
        ),
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
