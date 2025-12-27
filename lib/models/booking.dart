import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id;
  final String name;
  final String email;
  final String phone;
  final DateTime date;
  final String time;
  final String massageType;
  final String? serviceType; // 'massage' or 'soins'
  final String? serviceName; // The display name of the service (massage or treatment)
  final int duration; // Duration in minutes
  final String notes;
  final bool isAtHome;
  final String homeAddress;
  final String status; // 'en_attente', 'confirmed', 'cancelled'
  final DateTime createdAt;

  Booking({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.date,
    required this.time,
    required this.massageType,
    this.serviceType,
    this.serviceName,
    required this.duration,
    required this.notes,
    this.isAtHome = false,
    this.homeAddress = '',
    this.status = 'en_attente',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'date': Timestamp.fromDate(date),
      'time': time,
      'massageType': massageType,
      if (serviceType != null) 'serviceType': serviceType,
      if (serviceName != null) 'serviceName': serviceName,
      'duration': duration,
      'notes': notes,
      'isAtHome': isAtHome,
      'homeAddress': homeAddress,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      massageType: map['massageType'] ?? '',
      serviceType: map['serviceType'] as String?,
      serviceName: map['serviceName'] as String?,
      duration: (map['duration'] as num?)?.toInt() ?? 60, // Default to 60 minutes if not set
      notes: map['notes'] ?? '',
      isAtHome: map['isAtHome'] ?? false,
      homeAddress: map['homeAddress'] ?? '',
      status: map['status'] ?? 'en_attente',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Booking copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    DateTime? date,
    String? time,
    String? massageType,
    String? serviceType,
    String? serviceName,
    int? duration,
    String? notes,
    bool? isAtHome,
    String? homeAddress,
    String? status,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      date: date ?? this.date,
      time: time ?? this.time,
      massageType: massageType ?? this.massageType,
      serviceType: serviceType ?? this.serviceType,
      serviceName: serviceName ?? this.serviceName,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      isAtHome: isAtHome ?? this.isAtHome,
      homeAddress: homeAddress ?? this.homeAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

