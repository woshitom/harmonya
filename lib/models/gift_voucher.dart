import 'package:cloud_firestore/cloud_firestore.dart';

class GiftVoucher {
  final String? id;
  final String purchaserName;
  final String purchaserEmail;
  final String recipientName;
  final String recipientEmail;
  final double amount;
  final String? message;
  final String status; // 'pending', 'paid', 'used', 'expired'
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? paypalOrderId;
  final DateTime expiresAt;

  GiftVoucher({
    this.id,
    required this.purchaserName,
    required this.purchaserEmail,
    required this.recipientName,
    required this.recipientEmail,
    required this.amount,
    this.message,
    this.status = 'pending',
    required this.createdAt,
    this.paidAt,
    this.paypalOrderId,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'purchaserName': purchaserName,
      'purchaserEmail': purchaserEmail,
      'recipientName': recipientName,
      'recipientEmail': recipientEmail,
      'amount': amount,
      'message': message ?? '',
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'paypalOrderId': paypalOrderId ?? '',
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  factory GiftVoucher.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to safely convert to DateTime
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return GiftVoucher(
      id: id,
      purchaserName: map['purchaserName'] ?? '',
      purchaserEmail: map['purchaserEmail'] ?? '',
      recipientName: map['recipientName'] ?? '',
      recipientEmail: map['recipientEmail'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      message: map['message'],
      status: map['status'] ?? 'pending',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      paidAt: _parseDate(map['paidAt']),
      paypalOrderId: map['paypalOrderId'],
      expiresAt:
          _parseDate(map['expiresAt']) ??
          DateTime.now().add(const Duration(days: 365)),
    );
  }

  GiftVoucher copyWith({
    String? id,
    String? purchaserName,
    String? purchaserEmail,
    String? recipientName,
    String? recipientEmail,
    double? amount,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? paidAt,
    String? paypalOrderId,
    DateTime? expiresAt,
  }) {
    return GiftVoucher(
      id: id ?? this.id,
      purchaserName: purchaserName ?? this.purchaserName,
      purchaserEmail: purchaserEmail ?? this.purchaserEmail,
      recipientName: recipientName ?? this.recipientName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      paypalOrderId: paypalOrderId ?? this.paypalOrderId,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
