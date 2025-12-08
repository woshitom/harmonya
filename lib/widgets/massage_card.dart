import 'package:flutter/material.dart';

class MassageCard extends StatelessWidget {
  final bool isSmallScreen;
  final String title;
  final String description;
  final String zones;
  final String price;
  final String duration;

  const MassageCard({
    super.key,
    required this.isSmallScreen,
    required this.title,
    required this.description,
    required this.zones,
    required this.price,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(isSmallScreen ? 8 : 16),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: isSmallScreen ? 24 : 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
            const SizedBox(height: 16),
            if (zones.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.spa,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Zone du corps: $zones',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: isSmallScreen ? 16 : 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    duration,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
