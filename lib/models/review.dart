import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String? id;
  final String name; // Nom (surname)
  final String prenom; // Prénom (first name)
  final int rating; // 1-5
  final String comment;
  final bool approved;
  final DateTime createdAt;

  Review({
    this.id,
    required this.name,
    required this.prenom,
    required this.rating,
    required this.comment,
    this.approved = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'prenom': prenom,
      'rating': rating,
      'comment': comment,
      'approved': approved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      name: map['name'] ?? '',
      prenom: map['prenom'] ?? '',
      rating: map['rating'] ?? 5,
      comment: map['comment'] ?? '',
      approved: map['approved'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Review copyWith({
    String? id,
    String? name,
    String? prenom,
    int? rating,
    String? comment,
    bool? approved,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      name: name ?? this.name,
      prenom: prenom ?? this.prenom,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      approved: approved ?? this.approved,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  String get fullName => '$prenom $name'.trim();
  
  String get anonymizedName {
    if (prenom.isEmpty && name.isEmpty) {
      return 'A.';
    }
    if (prenom.isEmpty) {
      return '${name[0].toUpperCase()}.';
    }
    if (name.isEmpty) {
      return prenom;
    }
    // Return full first name + first letter of last name + dot
    return '$prenom ${name[0].toUpperCase()}.';
  }
}

