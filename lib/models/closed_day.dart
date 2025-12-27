import 'package:cloud_firestore/cloud_firestore.dart';

class ClosedDay {
  final String? id;
  final DateTime date;
  final String? reason; // Optional reason for closing

  ClosedDay({
    this.id,
    required this.date,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      if (reason != null) 'reason': reason,
    };
  }

  factory ClosedDay.fromMap(Map<String, dynamic> map, String id) {
    return ClosedDay(
      id: id,
      date: (map['date'] as Timestamp).toDate(),
      reason: map['reason'] as String?,
    );
  }

  ClosedDay copyWith({
    String? id,
    DateTime? date,
    String? reason,
  }) {
    return ClosedDay(
      id: id ?? this.id,
      date: date ?? this.date,
      reason: reason ?? this.reason,
    );
  }
}

