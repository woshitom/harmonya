import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';
import '../services/firebase_service.dart';

class AdminReviewList extends StatelessWidget {
  const AdminReviewList({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<Review>>(
      stream: firebaseService.getPendingReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const Center(child: Text('Aucun avis en attente'));
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
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
                          child: Text(
                            review.fullName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy à HH:mm',
                        'fr',
                      ).format(review.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _approveReview(
                            context,
                            firebaseService,
                            review.id!,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Approuver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _declineReview(
                            context,
                            firebaseService,
                            review.id!,
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Refuser'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveReview(
    BuildContext context,
    FirebaseService service,
    String id,
  ) async {
    try {
      await service.approveReview(id);
      if (context.mounted) {
        await showDialog(
          context: context,
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
                          'Avis approuvé',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'L\'avis a été approuvé avec succès et est maintenant visible sur le site.',
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
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog(
          context: context,
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
                      Icon(Icons.error, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Erreur', style: TextStyle(fontSize: 20)),
                      ),
                    ],
                  ),
                  content: Text(
                    'Une erreur s\'est produite lors de l\'approbation de l\'avis: ${e.toString()}',
                    style: const TextStyle(fontSize: 16),
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
      }
    }
  }

  Future<void> _declineReview(
    BuildContext context,
    FirebaseService service,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser l\'avis'),
        content: const Text(
          'Êtes-vous sûr de vouloir refuser cet avis? Il sera supprimé définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await service.declineReview(id);
        if (context.mounted) {
          await showDialog(
            context: context,
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
                        Icon(Icons.cancel, color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Avis refusé',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      'L\'avis a été refusé et supprimé avec succès.',
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
        }
      } catch (e) {
        if (context.mounted) {
          await showDialog(
            context: context,
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
                        Icon(Icons.error, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Erreur', style: TextStyle(fontSize: 20)),
                        ),
                      ],
                    ),
                    content: Text(
                      'Une erreur s\'est produite lors du refus de l\'avis: ${e.toString()}',
                      style: const TextStyle(fontSize: 16),
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
        }
      }
    }
  }
}
