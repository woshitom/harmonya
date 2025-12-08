import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/firebase_service.dart';

class ReviewForm extends StatefulWidget {
  final bool isSmallScreen;
  const ReviewForm({super.key, required this.isSmallScreen});

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prenomController = TextEditingController();
  final _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;
  final _firebaseService = FirebaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _prenomController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get values before setState to avoid any timing issues
    final name = _nameController.text.trim();
    final prenom = _prenomController.text.trim();
    final comment = _commentController.text.trim();

    if (name.isEmpty || prenom.isEmpty || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final review = Review(
        name: name,
        prenom: prenom,
        rating: _rating,
        comment: comment,
        approved: false,
        createdAt: DateTime.now(),
      );

      await _firebaseService.createReview(review);

      if (mounted) {
        // Show success dialog instead of snackbar
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
                          'Avis envoyé !',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Votre avis a été envoyé et sera publié après validation.',
                    style: TextStyle(fontSize: 16),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
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

        // Reset form after dialog is closed
        _formKey.currentState?.reset();
        _nameController.clear();
        _prenomController.clear();
        _commentController.clear();
        setState(() {
          _rating = 5;
        });
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
    return Container(
      padding: EdgeInsets.all(widget.isSmallScreen ? 16 : 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Laisser un avis',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: widget.isSmallScreen ? 24 : 32,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _prenomController,
              decoration: const InputDecoration(
                labelText: 'Prénom *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Note: ', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(width: 8),
                ...List.generate(
                  5,
                  (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Votre avis *',
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer votre avis';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer l\'avis'),
            ),
          ],
        ),
      ),
    );
  }
}
