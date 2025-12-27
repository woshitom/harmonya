import 'dart:math';
import 'package:flutter/material.dart';
import '../models/massage.dart';
import '../services/firebase_service.dart';

class AdminMassageList extends StatefulWidget {
  const AdminMassageList({super.key});

  @override
  State<AdminMassageList> createState() => _AdminMassageListState();
}

class _AdminMassageListState extends State<AdminMassageList> {
  final _firebaseService = FirebaseService();
  final ValueNotifier<bool> _isDraggingNotifier = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isDraggingNotifier.dispose();
    super.dispose();
  }

  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<Massage> massages,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create new list with reordered items
    final reorderedMassages = List<Massage>.from(massages);
    final item = reorderedMassages.removeAt(oldIndex);
    reorderedMassages.insert(newIndex, item);

    // Extract IDs in new order
    final massageIds = reorderedMassages.map((m) => m.id).toList();

    // Update order in Firestore
    try {
      await _firebaseService.updateMassageOrder(massageIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordre des massages mis à jour'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour de l\'ordre: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        StreamBuilder<List<Massage>>(
          stream: _firebaseService.getMassages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final massages = snapshot.data ?? [];

            if (massages.isEmpty) {
              return const Center(child: Text('Aucun massage enregistré'));
            }

            return ValueListenableBuilder<bool>(
              valueListenable: _isDraggingNotifier,
              builder: (context, isDragging, _) {
                return ReorderableListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 80),
                  buildDefaultDragHandles:
                      false, // Disable default right-side handles
                  proxyDecorator: (child, index, animation) {
                    final massage = massages[index];
                    // Detect when animation starts to set dragging state
                    animation.addStatusListener((status) {
                      if (status == AnimationStatus.forward) {
                        _isDraggingNotifier.value = true;
                      } else if (status == AnimationStatus.completed ||
                          status == AnimationStatus.dismissed) {
                        _isDraggingNotifier.value = false;
                      }
                    });
                    return Material(
                      elevation: 6,
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.drag_handle, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              massage.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    _isDraggingNotifier.value = false;
                    _onReorder(oldIndex, newIndex, massages);
                  },
                  onReorderEnd: (index) {
                    _isDraggingNotifier.value = false;
                  },
                  children: massages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final massage = entry.value;

                    return Card(
                      key: ValueKey(massage.id),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isDragging
                            ? Row(
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.grab,
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      massage.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Drag handle on the left with ReorderableDragStartListener
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.grab,
                                          child: Icon(
                                            Icons.drag_handle,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              massage.name,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.headlineMedium,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              massage.description,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                            ),
                                            if (massage.zones.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.spa,
                                                    size: 16,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Zones: ${massage.zones}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: massage.prices.map((
                                                price,
                                              ) {
                                                return Chip(
                                                  label: Text(
                                                    '${price.duration} min - ${price.price.toStringAsFixed(0)}€',
                                                  ),
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Edit and Delete buttons on the right
                                      IconButton(
                                        onPressed: () => _editMassage(
                                          context,
                                          _firebaseService,
                                          massage,
                                        ),
                                        icon: const Icon(Icons.edit),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        tooltip: 'Modifier',
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteMassage(
                                          context,
                                          _firebaseService,
                                          massage.id,
                                          massage.name,
                                        ),
                                        icon: const Icon(Icons.delete),
                                        color: Colors.red,
                                        tooltip: 'Supprimer',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _addMassage(context, _firebaseService),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un massage'),
          ),
        ),
      ],
    );
  }

  Future<void> _addMassage(
    BuildContext context,
    FirebaseService service,
  ) async {
    final result = await showDialog<Massage>(
      context: context,
      builder: (context) => const _MassageDialog(),
    );

    if (result != null) {
      try {
        await service.createMassage(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Massage ajouté avec succès'),
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

  Future<void> _editMassage(
    BuildContext context,
    FirebaseService service,
    Massage massage,
  ) async {
    final result = await showDialog<Massage>(
      context: context,
      builder: (context) => _MassageDialog(massage: massage),
    );

    if (result != null) {
      try {
        await service.updateMassage(result.id, result.toMap());
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Massage modifié avec succès'),
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

  Future<void> _deleteMassage(
    BuildContext context,
    FirebaseService service,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le massage'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$name"? Cette action est irréversible.',
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
        await service.deleteMassage(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Massage supprimé avec succès'),
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

class _MassageDialog extends StatefulWidget {
  final Massage? massage;

  const _MassageDialog({this.massage});

  @override
  State<_MassageDialog> createState() => _MassageDialogState();
}

class _MassageDialogState extends State<_MassageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zonesController = TextEditingController();
  final List<MassagePrice> _prices = [];
  late String _massageId;

  /// Generate a random 15-character string for the massage ID
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(15, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    if (widget.massage != null) {
      _massageId = widget.massage!.id;
      _idController.text = widget.massage!.id;
      _nameController.text = widget.massage!.name;
      _descriptionController.text = widget.massage!.description;
      _zonesController.text = widget.massage!.zones;
      _prices.addAll(widget.massage!.prices);
    } else {
      // Generate random ID for new massage
      _massageId = _generateRandomId();
      _idController.text = _massageId;
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _zonesController.dispose();
    super.dispose();
  }

  void _addPrice() {
    showDialog(context: context, builder: (context) => _PriceDialog()).then((
      result,
    ) {
      if (result != null && result is MassagePrice) {
        setState(() {
          _prices.add(result);
        });
      }
    });
  }

  void _removePrice(int index) {
    setState(() {
      _prices.removeAt(index);
    });
  }

  void _editPrice(int index) {
    showDialog(
      context: context,
      builder: (context) => _PriceDialog(price: _prices[index]),
    ).then((result) {
      if (result != null && result is MassagePrice) {
        setState(() {
          _prices[index] = result;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.massage != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Modifier le massage' : 'Ajouter un massage',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Show ID field (read-only for editing, auto-generated for new)
                        TextFormField(
                          controller: _idController,
                          decoration: InputDecoration(
                            labelText: 'ID',
                            prefixIcon: const Icon(Icons.tag),
                            helperText: isEditing
                                ? 'L\'ID ne peut pas être modifié'
                                : 'ID généré automatiquement',
                          ),
                          readOnly: true,
                          enabled: false,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom *',
                            prefixIcon: Icon(Icons.spa),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description *',
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer une description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _zonesController,
                          decoration: const InputDecoration(
                            labelText: 'Zones du corps',
                            hintText: 'ex: cervicales, dos, épaules',
                            prefixIcon: Icon(Icons.accessibility_new),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tarifs *',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            ElevatedButton.icon(
                              onPressed: _addPrice,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Ajouter un tarif'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_prices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Aucun tarif ajouté',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ..._prices.asMap().entries.map((entry) {
                            final index = entry.key;
                            final price = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text('${price.duration} min'),
                                subtitle: Text(
                                  '${price.price.toStringAsFixed(0)}€',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editPrice(index),
                                      tooltip: 'Modifier',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () => _removePrice(index),
                                      tooltip: 'Supprimer',
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        if (_prices.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Au moins un tarif est requis',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_prices.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez ajouter au moins un tarif',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final massage = Massage(
                            id: _massageId, // Use the generated or existing ID
                            name: _nameController.text.trim(),
                            description: _descriptionController.text.trim(),
                            zones: _zonesController.text.trim(),
                            prices: _prices,
                            createdAt:
                                widget.massage?.createdAt ??
                                DateTime.now(), // Use existing createdAt or current time
                            order:
                                widget.massage?.order ??
                                0, // Order will be set by createMassage
                          );

                          Navigator.pop(context, massage);
                        }
                      },
                      child: Text(isEditing ? 'Modifier' : 'Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  final MassagePrice? price;

  const _PriceDialog({this.price});

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.price != null) {
      _durationController.text = widget.price!.duration.toString();
      _priceController.text = widget.price!.price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.price == null ? 'Ajouter un tarif' : 'Modifier le tarif',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durée (minutes) *',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer une durée';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'Veuillez entrer un nombre valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Prix (€) *',
                prefixIcon: Icon(Icons.euro),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un prix';
                }
                final price = double.tryParse(value.replaceAll(',', '.'));
                if (price == null || price <= 0) {
                  return 'Veuillez entrer un prix valide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final duration = int.parse(_durationController.text.trim());
              final price = double.parse(
                _priceController.text.trim().replaceAll(',', '.'),
              );

              Navigator.pop(
                context,
                MassagePrice(duration: duration, price: price),
              );
            }
          },
          child: Text(widget.price == null ? 'Ajouter' : 'Modifier'),
        ),
      ],
    );
  }
}
