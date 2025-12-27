import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/massage.dart';
import '../services/firebase_service.dart';

/// Generic service list widget that works with both massages and treatments
class AdminServiceList extends StatefulWidget {
  final bool isTreatment; // true for treatments, false for massages
  final String emptyMessage;
  final String addButtonLabel;
  final String addSuccessMessage;
  final String updateSuccessMessage;
  final String deleteSuccessMessage;
  final String reorderSuccessMessage;

  const AdminServiceList({
    super.key,
    required this.isTreatment,
    this.emptyMessage = 'Aucun service enregistré',
    this.addButtonLabel = 'Ajouter un service',
    this.addSuccessMessage = 'Service ajouté avec succès',
    this.updateSuccessMessage = 'Service modifié avec succès',
    this.deleteSuccessMessage = 'Service supprimé avec succès',
    this.reorderSuccessMessage = 'Ordre des services mis à jour',
  });

  @override
  State<AdminServiceList> createState() => _AdminServiceListState();
}

class _AdminServiceListState extends State<AdminServiceList> {
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
    List<Massage> services,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Create new list with reordered items
    final reorderedServices = List<Massage>.from(services);
    final item = reorderedServices.removeAt(oldIndex);
    reorderedServices.insert(newIndex, item);

    // Extract IDs in new order
    final serviceIds = reorderedServices.map((m) => m.id).toList();

    // Update order in Firestore
    try {
      if (widget.isTreatment) {
        await _firebaseService.updateTreatmentOrder(serviceIds);
      } else {
        await _firebaseService.updateMassageOrder(serviceIds);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.reorderSuccessMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
          stream: widget.isTreatment
              ? _firebaseService.getTreatments()
              : _firebaseService.getMassages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final services = snapshot.data ?? [];

            if (services.isEmpty) {
              return Center(child: Text(widget.emptyMessage));
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
                    final service = services[index];
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
                            Icon(
                              Icons.drag_handle,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              service.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    _isDraggingNotifier.value = false;
                    _onReorder(oldIndex, newIndex, services);
                  },
                  onReorderEnd: (index) {
                    _isDraggingNotifier.value = false;
                  },
                  children: services.asMap().entries.map((entry) {
                    final index = entry.key;
                    final service = entry.value;

                    return Card(
                      key: ValueKey(service.id),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: isDragging
                        ? Row(
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.grab,
                                child: ReorderableDragStartListener(
                                  index: index,
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  service.name,
                                  style: Theme.of(context).textTheme.titleMedium,
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
                                  MouseRegion(
                                    cursor: SystemMouseCursors.grab,
                                    child: ReorderableDragStartListener(
                                      index: index,
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                service.name,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.headlineMedium,
                                              ),
                                            ),
                                            // Badges for Best Seller and New
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (service.isBestSeller)
                                                  Container(
                                                    margin: const EdgeInsets.only(
                                                      left: 8,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Meilleure vente',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                if (service.isNew)
                                                  Container(
                                                    margin: const EdgeInsets.only(
                                                      left: 6,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green,
                                                      borderRadius:
                                                          BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      'Nouveau',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          service.description,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        if (service.zones.isNotEmpty) ...[
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
                                                  'Zones: ${service.zones}',
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
                                          children: service.prices.map((price) {
                                            return Chip(
                                              label: Text(
                                                '${price.duration} min - ${price.price.toStringAsFixed(0)}€',
                                              ),
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Edit and Delete buttons on the right
                                  IconButton(
                                    onPressed: () => _editService(
                                      context,
                                      _firebaseService,
                                      service,
                                    ),
                                    icon: const Icon(Icons.edit),
                                    color: Theme.of(context).colorScheme.primary,
                                    tooltip: 'Modifier',
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteService(
                                      context,
                                      _firebaseService,
                                      service.id,
                                      service.name,
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
            onPressed: () => _addService(context, _firebaseService),
            icon: const Icon(Icons.add),
            label: Text(widget.addButtonLabel),
          ),
        ),
      ],
    );
  }

  Future<void> _addService(
    BuildContext context,
    FirebaseService service,
  ) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Open in a new page for small screens
      await Navigator.push<Massage>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isTreatment ? 'Ajouter un soin' : 'Ajouter un massage',
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _ServiceDialog(
                isTreatment: widget.isTreatment,
                isFullPage: true,
                onSave: (serviceResult) async {
                  try {
                    if (widget.isTreatment) {
                      await service.createTreatment(serviceResult);
                    } else {
                      await service.createMassage(serviceResult);
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop(serviceResult);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.addSuccessMessage),
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
      final result = await showDialog<Massage>(
        context: context,
        builder: (context) => _ServiceDialog(isTreatment: widget.isTreatment),
      );

      if (result != null) {
        try {
          if (widget.isTreatment) {
            await service.createTreatment(result);
          } else {
            await service.createMassage(result);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.addSuccessMessage),
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

  Future<void> _editService(
    BuildContext context,
    FirebaseService service,
    Massage serviceItem,
  ) async {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    if (isSmallScreen) {
      // Open in a new page for small screens
      await Navigator.push<Massage>(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isTreatment ? 'Modifier le soin' : 'Modifier le massage',
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _ServiceDialog(
                massage: serviceItem,
                isTreatment: widget.isTreatment,
                isFullPage: true,
                onSave: (serviceResult) async {
                  try {
                    if (widget.isTreatment) {
                      await service.updateTreatment(
                        serviceResult.id,
                        serviceResult.toMap(),
                      );
                    } else {
                      await service.updateMassage(
                        serviceResult.id,
                        serviceResult.toMap(),
                      );
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop(serviceResult);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.updateSuccessMessage),
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
      final result = await showDialog<Massage>(
        context: context,
        builder: (context) => _ServiceDialog(
          massage: serviceItem,
          isTreatment: widget.isTreatment,
        ),
      );

      if (result != null) {
        try {
          if (widget.isTreatment) {
            await service.updateTreatment(result.id, result.toMap());
          } else {
            await service.updateMassage(result.id, result.toMap());
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.updateSuccessMessage),
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

  Future<void> _deleteService(
    BuildContext context,
    FirebaseService service,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le service'),
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
        if (widget.isTreatment) {
          await service.deleteTreatment(id);
        } else {
          await service.deleteMassage(id);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.deleteSuccessMessage),
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

class _ServiceDialog extends StatefulWidget {
  final Massage? massage;
  final bool isTreatment;
  final bool isFullPage;
  final Function(Massage)? onSave;

  const _ServiceDialog({
    this.massage,
    required this.isTreatment,
    this.isFullPage = false,
    this.onSave,
  });

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _zonesController = TextEditingController();
  final List<MassagePrice> _prices = [];
  late String _serviceId;
  Uint8List? _selectedImageBytes; // Image bytes (works on both web and mobile)
  String? _imageUrl; // Existing image URL from Firestore
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _isBestSeller = false;
  bool _isNew = false;
  final _firebaseService = FirebaseService();
  final _imagePicker = ImagePicker();

  /// Generate a random 15-character string for the service ID
  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(15, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  void initState() {
    super.initState();
    if (widget.massage != null) {
      _serviceId = widget.massage!.id;
      _idController.text = widget.massage!.id;
      _nameController.text = widget.massage!.name;
      _descriptionController.text = widget.massage!.description;
      _zonesController.text = widget.massage!.zones;
      _prices.addAll(widget.massage!.prices);
      _imageUrl = widget.massage!.imageUrl;
      _isBestSeller = widget.massage!.isBestSeller;
      _isNew = widget.massage!.isNew;
    } else {
      // Generate random ID for new service
      _serviceId = _generateRandomId();
      _idController.text = _serviceId;
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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Read bytes directly (works on both web and mobile)
        final bytes = await pickedFile.readAsBytes();

        // Check file size limit: 2 MB = 2 * 1024 * 1024 bytes
        const maxSizeBytes = 2 * 1024 * 1024; // 2 MB
        if (bytes.length > maxSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'L\'image est trop grande. Taille maximale: 2 Mo. Taille actuelle: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} Mo',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImageBytes = bytes;
          _imageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageIfNeeded() async {
    if (_selectedImageBytes == null) {
      return _imageUrl; // Return existing URL if no new image selected
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Use bytes for both web and mobile
      final uploadedUrl = await _firebaseService.uploadServiceImageBytes(
        _selectedImageBytes!,
        _serviceId,
        widget.isTreatment,
      );
      return uploadedUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.massage != null;
    final serviceType = widget.isTreatment ? 'soin' : 'massage';

    final formContent = Form(
      key: _formKey,
      child: widget.isFullPage
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormFields(isEditing, serviceType),
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
                      onPressed: (_isUploadingImage || _isSaving)
                          ? null
                          : () => _handleSave(isEditing, serviceType),
                      child: (_isUploadingImage || _isSaving)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Modifier' : 'Ajouter'),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing
                      ? 'Modifier le $serviceType'
                      : 'Ajouter un $serviceType',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildFormFields(isEditing, serviceType),
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
                      onPressed: (_isUploadingImage || _isSaving)
                          ? null
                          : () => _handleSave(isEditing, serviceType),
                      child: (_isUploadingImage || _isSaving)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Modifier' : 'Ajouter'),
                    ),
                  ],
                ),
              ],
            ),
    );

    if (widget.isFullPage) {
      return formContent;
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Padding(padding: const EdgeInsets.all(24), child: formContent),
      ),
    );
  }

  Widget _buildFormFields(bool isEditing, String serviceType) {
    return Column(
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
        // Image Upload Section
        Text('Image', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (_isUploadingImage || _isSaving) ? null : () => _pickImage(),
                icon: _isUploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(
                  _isUploadingImage
                      ? 'Upload en cours...'
                      : _imageUrl != null || _selectedImageBytes != null
                      ? 'Changer l\'image'
                      : 'Ajouter une image',
                ),
              ),
            ),
            if (_imageUrl != null || _selectedImageBytes != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _selectedImageBytes = null;
                    _imageUrl = null;
                  });
                },
                tooltip: 'Supprimer l\'image',
              ),
            ],
          ],
        ),
        if (_selectedImageBytes != null || _imageUrl != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) {
                final isSmallScreen = MediaQuery.of(context).size.width < 600;
                // Miniature thumbnail: maintain same aspect ratio as landing page cards
                // Landing page uses childAspectRatio: 0.75 (small) or 0.85 (large)
                // This means width/height = 0.75 or 0.85
                // Card height is 250 (small) or 300 (large)
                // So card width would be: 250*0.75=187.5 (small) or 300*0.85=255 (large)
                // For miniature, scale down proportionally (about 40% size)
                final thumbnailHeight = isSmallScreen ? 100.0 : 120.0;
                // Maintain the same aspect ratio as landing page cards
                final aspectRatio = isSmallScreen ? 0.75 : 0.85;
                final thumbnailWidth = thumbnailHeight * aspectRatio;
                return SizedBox(
                  height: thumbnailHeight,
                  width: thumbnailWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _selectedImageBytes != null
                          ? Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            )
                          : _imageUrl != null
                          ? Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.broken_image),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 24),
        // Best Seller and New checkboxes
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Meilleure vente'),
                value: _isBestSeller,
                onChanged: (value) {
                  setState(() {
                    _isBestSeller = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Nouveau'),
                value: _isNew,
                onChanged: (value) {
                  setState(() {
                    _isNew = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tarifs *', style: Theme.of(context).textTheme.titleMedium),
            ElevatedButton.icon(
              onPressed: (_isUploadingImage || _isSaving) ? null : _addPrice,
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
                subtitle: Text('${price.price.toStringAsFixed(0)}€'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: (_isUploadingImage || _isSaving) ? null : () => _editPrice(index),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: (_isUploadingImage || _isSaving) ? null : () => _removePrice(index),
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
    );
  }

  Future<void> _handleSave(bool isEditing, String serviceType) async {
    if (_formKey.currentState!.validate()) {
      if (_prices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez ajouter au moins un tarif'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Upload image if a new one was selected
      final finalImageUrl = await _uploadImageIfNeeded();
      if (_selectedImageBytes != null && finalImageUrl == null) {
        // Upload failed, don't proceed
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final service = Massage(
          id: _serviceId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          zones: _zonesController.text.trim(),
          prices: _prices,
          createdAt: widget.massage?.createdAt ?? DateTime.now(),
          order: widget.massage?.order ?? 0,
          imageUrl: finalImageUrl,
          isBestSeller: _isBestSeller,
          isNew: _isNew,
        );

        if (mounted) {
          if (widget.isFullPage && widget.onSave != null) {
            await widget.onSave!(service);
          } else {
            Navigator.pop(context, service);
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
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
