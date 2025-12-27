import 'package:cloud_firestore/cloud_firestore.dart';

class MassagePrice {
  final int duration; // Duration in minutes
  final double price; // Price in euros

  MassagePrice({
    required this.duration,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'duration': duration,
      'price': price,
    };
  }

  factory MassagePrice.fromMap(Map<String, dynamic> map) {
    return MassagePrice(
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Massage {
  final String id;
  final String name;
  final String description;
  final String zones; // Body zones
  final List<MassagePrice> prices;
  final DateTime createdAt;
  final int order; // Order for display (lower = first)
  final String? imageUrl; // Firebase Storage URL for the image
  final bool isBestSeller; // Mark as best seller
  final bool isNew; // Mark as new

  Massage({
    required this.id,
    required this.name,
    required this.description,
    required this.zones,
    required this.prices,
    required this.createdAt,
    required this.order,
    this.imageUrl,
    this.isBestSeller = false,
    this.isNew = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'zones': zones,
      'prices': prices.map((p) => p.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'order': order,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'isBestSeller': isBestSeller,
      'isNew': isNew,
    };
  }

  factory Massage.fromMap(Map<String, dynamic> map, String id) {
    final pricesList = map['prices'] as List<dynamic>? ?? [];
    return Massage(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      zones: map['zones'] ?? '',
      prices: pricesList.map((p) => MassagePrice.fromMap(p as Map<String, dynamic>)).toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      isBestSeller: map['isBestSeller'] as bool? ?? false,
      isNew: map['isNew'] as bool? ?? false,
    );
  }

  /// Get the minimum price from all price options
  double get minPrice {
    if (prices.isEmpty) return 0.0;
    return prices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  /// Get the maximum price from all price options
  double get maxPrice {
    if (prices.isEmpty) return 0.0;
    return prices.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  /// Format price range as string (e.g., "45€" or "95€ / 115€")
  String get priceRange {
    if (prices.isEmpty) return '0€';
    if (prices.length == 1) {
      return '${prices.first.price.toInt()}€';
    }
    final sortedPrices = [...prices]..sort((a, b) => a.price.compareTo(b.price));
    return sortedPrices.map((p) => '${p.price.toInt()}€').join(' / ');
  }

  /// Format duration range as string (e.g., "30 min" or "60 min / 90 min")
  String get durationRange {
    if (prices.isEmpty) return '0 min';
    if (prices.length == 1) {
      return '${prices.first.duration} min';
    }
    final sortedDurations = [...prices]..sort((a, b) => a.duration.compareTo(b.duration));
    return sortedDurations.map((p) => '${p.duration} min').join(' / ');
  }

  /// Get a unique ID for a specific duration/price combination
  /// Format: "massageId_duration" (e.g., "cocooning_60", "cocooning_90")
  String getMassageOptionId(int duration) {
    return '${id}_$duration';
  }

  Massage copyWith({
    String? id,
    String? name,
    String? description,
    String? zones,
    List<MassagePrice>? prices,
    DateTime? createdAt,
    int? order,
    String? imageUrl,
    bool? isBestSeller,
    bool? isNew,
  }) {
    return Massage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      zones: zones ?? this.zones,
      prices: prices ?? this.prices,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
      imageUrl: imageUrl ?? this.imageUrl,
      isBestSeller: isBestSeller ?? this.isBestSeller,
      isNew: isNew ?? this.isNew,
    );
  }
}

