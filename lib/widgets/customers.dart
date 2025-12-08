import 'package:flutter/material.dart';
import '../models/customer.dart';
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
              return const Center(
                child: Text('Aucun client enregistré'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                    style: Theme.of(context).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.email,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.phone,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _editCustomer(context, firebaseService, customer),
                              icon: const Icon(Icons.edit),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              onPressed: () => _deleteCustomer(context, firebaseService, customer.id),
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              tooltip: 'Supprimer',
                            ),
                          ],
                        ),
                        if (customer.massageTypes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Types de massage:',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: customer.massageTypes.map((type) {
                              return Chip(
                                label: Text(type),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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

  Future<void> _addCustomer(BuildContext context, FirebaseService service) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => const _CustomerDialog(),
    );

    if (result != null) {
      try {
        await service.createCustomer(result);
        if (context.mounted) {
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
    }
  }

  Future<void> _editCustomer(
    BuildContext context,
    FirebaseService service,
    Customer customer,
  ) async {
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

class _CustomerDialog extends StatefulWidget {
  final Customer? customer;

  const _CustomerDialog({this.customer});

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<String> _massageTypes = [];
  final _massageTypeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _emailController.text = widget.customer!.email;
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _massageTypes.addAll(widget.customer!.massageTypes);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _massageTypeController.dispose();
    super.dispose();
  }

  void _addMassageType() {
    final type = _massageTypeController.text.trim();
    if (type.isNotEmpty && !_massageTypes.contains(type)) {
      setState(() {
        _massageTypes.add(type);
        _massageTypeController.clear();
      });
    }
  }

  void _removeMassageType(String type) {
    setState(() {
      _massageTypes.remove(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.customer == null ? 'Ajouter un client' : 'Modifier le client',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
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
                      Text(
                        'Types de massage',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _massageTypeController,
                              decoration: const InputDecoration(
                                labelText: 'Ajouter un type de massage',
                                hintText: 'Ex: Découverte',
                              ),
                              onFieldSubmitted: (_) => _addMassageType(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addMassageType,
                            icon: const Icon(Icons.add),
                            tooltip: 'Ajouter',
                          ),
                        ],
                      ),
                      if (_massageTypes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _massageTypes.map((type) {
                            return Chip(
                              label: Text(type),
                              onDeleted: () => _removeMassageType(type),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final customer = Customer(
                          id: _emailController.text.trim(),
                          email: _emailController.text.trim(),
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          massageTypes: _massageTypes,
                        );
                        Navigator.of(context).pop(customer);
                      }
                    },
                    child: Text(widget.customer == null ? 'Ajouter' : 'Modifier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

