import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../models/massage.dart';
import '../services/firebase_service.dart';

class Customers extends StatelessWidget {
  const Customers({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return Stack(
      children: [
        StreamBuilder<List<Customer>>(
          stream: firebaseService.getCustomers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final customers = snapshot.data ?? [];

            if (customers.isEmpty) {
              return const Center(child: Text('Aucun client enregistré'));
            }

            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.phone,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _editCustomer(
                                context,
                                firebaseService,
                                customer,
                              ),
                              icon: const Icon(Icons.edit),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              onPressed: () => _deleteCustomer(
                                context,
                                firebaseService,
                                customer.id,
                              ),
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                        if (customer.massageTypesNames.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Types de massage:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: customer.massageTypesNames.map((type) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  type,
                                  softWrap: true,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (customer.treatmentTypesNames.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Types de soins:',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: customer.treatmentTypesNames.map((type) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  type,
                                  softWrap: true,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _addCustomer(context, firebaseService),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un client'),
          ),
        ),
      ],
    );
  }

  Future<void> _addCustomer(
    BuildContext context,
    FirebaseService service,
  ) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Open in a new page for small screens
      await Navigator.push<Customer>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Ajouter un client'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _CustomerDialog(
                isFullPage: true,
                onSave: (customer) async {
                  try {
                    await service.createCustomer(customer);
                    if (context.mounted) {
                      Navigator.of(context).pop(customer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Client ajouté avec succès'),
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
                },
              ),
            ),
          ),
        ),
      );
    } else {
      // Open in a dialog for large screens
      await showDialog<Customer>(
        context: context,
        builder: (context) => _CustomerDialog(
          onSave: (customer) async {
            try {
              await service.createCustomer(customer);
              if (context.mounted) {
                Navigator.of(context).pop(customer);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Client ajouté avec succès'),
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
          },
        ),
      );
    }
  }

  Future<void> _editCustomer(
    BuildContext context,
    FirebaseService service,
    Customer customer,
  ) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Open in a new page for small screens
      await Navigator.push<Customer>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Modifier le client'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _CustomerDialog(
                customer: customer,
                isFullPage: true,
                onSave: (updatedCustomer) async {
                  try {
                    await service.updateCustomer(
                      updatedCustomer.id,
                      updatedCustomer.toMap(),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(updatedCustomer);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Client modifié avec succès'),
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
                },
              ),
            ),
          ),
        ),
      );
    } else {
      // Open in a dialog for large screens
      final result = await showDialog<Customer>(
        context: context,
        builder: (context) => _CustomerDialog(customer: customer),
      );

      if (result != null) {
        try {
          await service.updateCustomer(result.id, result.toMap());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Client modifié avec succès'),
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

  Future<void> _deleteCustomer(
    BuildContext context,
    FirebaseService service,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce client? Cette action est irréversible.',
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
        await service.deleteCustomer(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client supprimé avec succès'),
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

class _WrappableChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;
  final Color? backgroundColor;

  const _WrappableChip({
    required this.label,
    this.onDeleted,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (onDeleted != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDeleted,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  final Customer? customer;
  final bool isFullPage;
  final Function(Customer)? onSave;

  const _CustomerDialog({this.customer, this.isFullPage = false, this.onSave});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _selectedMassageIds = [];
  List<Massage> _availableMassages = [];
  List<Massage> _availableTreatments = [];
  bool _isLoadingMassages = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _emailController.text = widget.customer!.email;
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      // Load both massageTypes and treatmentTypes into _selectedMassageIds
      // (we'll separate them when saving)
      _selectedMassageIds.addAll(widget.customer!.massageTypes);
      _selectedMassageIds.addAll(widget.customer!.treatmentTypes);
    }
    _loadMassages();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadMassages() async {
    try {
      final firebaseService = FirebaseService();
      final results = await Future.wait([
        firebaseService.getMassagesOnce(),
        firebaseService.getTreatmentsOnce(),
      ]);
      setState(() {
        _availableMassages = results[0];
        _availableTreatments = results[1];
        _isLoadingMassages = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMassages = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMassageSelection(String massageId) {
    setState(() {
      if (_selectedMassageIds.contains(massageId)) {
        _selectedMassageIds.remove(massageId);
      } else {
        _selectedMassageIds.add(massageId);
      }
    });
  }

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: widget.isFullPage
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormFields(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _isSaving = true;
                                });

                                try {
                                  // Separate selected IDs into massages and treatments
                                  final selectedMassageIds = _selectedMassageIds
                                      .where(
                                        (id) => _availableMassages.any(
                                          (m) => m.id == id,
                                        ),
                                      )
                                      .toList();
                                  final selectedTreatmentIds =
                                      _selectedMassageIds
                                          .where(
                                            (id) => _availableTreatments.any(
                                              (t) => t.id == id,
                                            ),
                                          )
                                          .toList();

                                  // Build names arrays matching the IDs arrays
                                  final selectedMassageNames =
                                      selectedMassageIds.map((id) {
                                        final massage = _availableMassages
                                            .firstWhere(
                                              (m) => m.id == id,
                                              orElse: () => Massage(
                                                id: id,
                                                name:
                                                    id, // Fallback to ID if not found
                                                description: '',
                                                zones: '',
                                                prices: [],
                                                createdAt: DateTime.now(),
                                                order: 0,
                                              ),
                                            );
                                        return massage.name;
                                      }).toList();

                                  final selectedTreatmentNames =
                                      selectedTreatmentIds.map((id) {
                                        final treatment = _availableTreatments
                                            .firstWhere(
                                              (t) => t.id == id,
                                              orElse: () => Massage(
                                                id: id,
                                                name:
                                                    id, // Fallback to ID if not found
                                                description: '',
                                                zones: '',
                                                prices: [],
                                                createdAt: DateTime.now(),
                                                order: 0,
                                              ),
                                            );
                                        return treatment.name;
                                      }).toList();

                                  final customer = Customer(
                                    id: _emailController.text.trim(),
                                    email: _emailController.text.trim(),
                                    name: _nameController.text.trim(),
                                    phone: _phoneController.text.trim(),
                                    massageTypes: selectedMassageIds,
                                    treatmentTypes: selectedTreatmentIds,
                                    massageTypesNames: selectedMassageNames,
                                    treatmentTypesNames: selectedTreatmentNames,
                                  );
                                  if (widget.onSave != null) {
                                    await widget.onSave!(customer);
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isSaving = false;
                                    });
                                  }
                                }
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              widget.customer == null ? 'Ajouter' : 'Modifier',
                            ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Text(
                    widget.customer == null
                        ? 'Ajouter un client'
                        : 'Modifier le client',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _buildFormFields(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isSaving = true;
                                  });

                                  try {
                                    // Separate selected IDs into massages and treatments
                                    final selectedMassageIds =
                                        _selectedMassageIds
                                            .where(
                                              (id) => _availableMassages.any(
                                                (m) => m.id == id,
                                              ),
                                            )
                                            .toList();
                                    final selectedTreatmentIds =
                                        _selectedMassageIds
                                            .where(
                                              (id) => _availableTreatments.any(
                                                (t) => t.id == id,
                                              ),
                                            )
                                            .toList();

                                    // Build names arrays matching the IDs arrays
                                    final selectedMassageNames =
                                        selectedMassageIds.map((id) {
                                          final massage = _availableMassages
                                              .firstWhere(
                                                (m) => m.id == id,
                                                orElse: () => Massage(
                                                  id: id,
                                                  name:
                                                      id, // Fallback to ID if not found
                                                  description: '',
                                                  zones: '',
                                                  prices: [],
                                                  createdAt: DateTime.now(),
                                                  order: 0,
                                                ),
                                              );
                                          return massage.name;
                                        }).toList();

                                    final selectedTreatmentNames =
                                        selectedTreatmentIds.map((id) {
                                          final treatment = _availableTreatments
                                              .firstWhere(
                                                (t) => t.id == id,
                                                orElse: () => Massage(
                                                  id: id,
                                                  name:
                                                      id, // Fallback to ID if not found
                                                  description: '',
                                                  zones: '',
                                                  prices: [],
                                                  createdAt: DateTime.now(),
                                                  order: 0,
                                                ),
                                              );
                                          return treatment.name;
                                        }).toList();

                                    final customer = Customer(
                                      id: _emailController.text.trim(),
                                      email: _emailController.text.trim(),
                                      name: _nameController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                      massageTypes: selectedMassageIds,
                                      treatmentTypes: selectedTreatmentIds,
                                      massageTypesNames: selectedMassageNames,
                                      treatmentTypesNames:
                                          selectedTreatmentNames,
                                    );
                                    if (widget.isFullPage &&
                                        widget.onSave != null) {
                                      await widget.onSave!(customer);
                                    } else {
                                      Navigator.of(context).pop(customer);
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isSaving = false;
                                      });
                                    }
                                  }
                                }
                              },
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.customer == null
                                    ? 'Ajouter'
                                    : 'Modifier',
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email *',
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: widget.customer == null, // Email cannot be changed
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer l\'email';
            }
            if (!value.contains('@')) {
              return 'Veuillez entrer un email valide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom *',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer le nom';
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Veuillez entrer le numéro de téléphone';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Text('Massages', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_isLoadingMassages)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_availableMassages.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Aucun massage disponible',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _availableMassages.map((massage) {
                final isSelected = _selectedMassageIds.contains(massage.id);
                return CheckboxListTile(
                  title: Text(massage.name),
                  value: isSelected,
                  onChanged: (_) => _toggleMassageSelection(massage.id),
                  dense: true,
                );
              }).toList(),
            ),
          ),
        if (_availableMassages.isNotEmpty &&
            _selectedMassageIds.any(
              (id) => _availableMassages.any((m) => m.id == id),
            )) ...[
          const SizedBox(height: 12),
          Text(
            'Massages sélectionnés:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMassageIds
                .where((id) => _availableMassages.any((m) => m.id == id))
                .map((massageId) {
                  final massage = _availableMassages.firstWhere(
                    (m) => m.id == massageId,
                  );
                  return _WrappableChip(
                    label: massage.name,
                    onDeleted: () => _toggleMassageSelection(massageId),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  );
                })
                .toList(),
          ),
        ],
        const SizedBox(height: 24),
        Text('Soins', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_isLoadingMassages)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_availableTreatments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Aucun soin disponible',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _availableTreatments.map((treatment) {
                final isSelected = _selectedMassageIds.contains(treatment.id);
                return CheckboxListTile(
                  title: Text(treatment.name),
                  value: isSelected,
                  onChanged: (_) => _toggleMassageSelection(treatment.id),
                  dense: true,
                );
              }).toList(),
            ),
          ),
        if (_availableTreatments.isNotEmpty &&
            _selectedMassageIds.any(
              (id) => _availableTreatments.any((t) => t.id == id),
            )) ...[
          const SizedBox(height: 12),
          Text(
            'Soins sélectionnés:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedMassageIds
                .where((id) => _availableTreatments.any((t) => t.id == id))
                .map((treatmentId) {
                  final treatment = _availableTreatments.firstWhere(
                    (t) => t.id == treatmentId,
                  );
                  return _WrappableChip(
                    label: treatment.name,
                    onDeleted: () => _toggleMassageSelection(treatmentId),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  );
                })
                .toList(),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formContent = _buildFormContent();

    if (widget.isFullPage) {
      return formContent;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: formContent,
      ),
    );
  }
}
