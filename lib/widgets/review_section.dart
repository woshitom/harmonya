import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';
import '../services/firebase_service.dart';

class ReviewSection extends StatelessWidget {
  final bool isSmallScreen;
  const ReviewSection({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return StreamBuilder<List<Review>>(
      stream: firebaseService.getApprovedReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: SelectableText('Erreur: ${snapshot.error}'));
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Avis de nos clientes',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: isSmallScreen ? 24 : 32,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth > 900
                    ? 900.0
                    : constraints.maxWidth;

                return Column(
                  children: reviews.map((review) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Center(
                        child: SizedBox(
                          width: maxWidth,
                          child: Card(
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.anonymizedName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: List.generate(
                                                5,
                                                (i) => Icon(
                                                  i < review.rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    review.comment,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(height: 1.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    DateFormat(
                                      'dd MMMM yyyy',
                                      'fr',
                                    ).format(review.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
