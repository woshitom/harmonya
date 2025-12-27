import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../models/customer.dart';
import '../models/gift_voucher.dart';
import '../models/massage.dart';
import '../models/closed_day.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: FirebaseStorage.instance.bucket,
  );

  // Bookings
  Future<String> createBooking(Booking booking) async {
    final docRef = await _firestore.collection('bookings').add(booking.toMap());
    return docRef.id;
  }

  Stream<List<Booking>> getBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Booking.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> updateBooking(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('bookings').doc(id).update(updates);
  }

  Future<void> deleteBooking(String id) async {
    await _firestore.collection('bookings').doc(id).delete();
  }

  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    // Get start and end of the selected date
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // If composite index is missing, fallback to fetching all and filtering
      // This is less efficient but works without requiring index setup
      final allBookings = await _firestore.collection('bookings').get();

      final bookings = allBookings.docs
          .map((doc) => Booking.fromMap(doc.data(), doc.id))
          .where((booking) {
            final bookingDate = booking.date;
            return bookingDate.year == date.year &&
                bookingDate.month == date.month &&
                bookingDate.day == date.day;
          })
          .toList();

      return bookings;
    }
  }

  // Reviews
  Future<String> createReview(Review review) async {
    final docRef = await _firestore.collection('reviews').add(review.toMap());
    return docRef.id;
  }

  Stream<List<Review>> getApprovedReviews() {
    return _firestore
        .collection('reviews')
        .where('approved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<Map<String, dynamic>> getAverageRating() {
    return _firestore
        .collection('reviews')
        .where('approved', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return {'rating': 0.0, 'count': 0};
          }

          int totalRating = 0;
          for (var doc in snapshot.docs) {
            final rating = doc.data()['rating'] as int? ?? 0;
            totalRating += rating;
          }

          return {
            'rating': totalRating / snapshot.docs.length,
            'count': snapshot.docs.length,
          };
        });
  }

  Future<Map<String, dynamic>> getAverageRatingOnce() async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('approved', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) {
      return {'rating': 0.0, 'count': 0};
    }

    int totalRating = 0;
    for (var doc in snapshot.docs) {
      final rating = doc.data()['rating'] as int? ?? 0;
      totalRating += rating;
    }

    return {
      'rating': totalRating / snapshot.docs.length,
      'count': snapshot.docs.length,
    };
  }

  Stream<List<Review>> getAllReviews() {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Review>> getPendingReviews() {
    return _firestore
        .collection('reviews')
        .where('approved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> approveReview(String id) async {
    await _firestore.collection('reviews').doc(id).update({'approved': true});
  }

  Future<void> declineReview(String id) async {
    await _firestore.collection('reviews').doc(id).delete();
  }

  // Customers
  Stream<List<Customer>> getCustomers() {
    return _firestore.collection('customers').snapshots().map((snapshot) {
      final customers = snapshot.docs
          .map((doc) => Customer.fromMap(doc.data(), doc.id))
          .toList();
      // Sort by name client-side
      customers.sort((a, b) => a.name.compareTo(b.name));
      return customers;
    });
  }

  Future<void> createCustomer(Customer customer) async {
    final customerData = customer.toMap();
    customerData['added_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('customers').doc(customer.id).set(customerData);
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('customers').doc(id).update(updates);
  }

  Future<void> deleteCustomer(String id) async {
    await _firestore.collection('customers').doc(id).delete();
  }

  // Gift Vouchers
  Future<String> createGiftVoucher(GiftVoucher voucher) async {
    final docRef = await _firestore
        .collection('giftVouchers')
        .add(voucher.toMap());
    return docRef.id;
  }

  Future<void> updateGiftVoucher(
    String id,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('giftVouchers').doc(id).update(updates);
  }

  Stream<List<GiftVoucher>> getGiftVouchers() {
    return _firestore
        .collection('giftVouchers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GiftVoucher.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Massages
  Stream<List<Massage>> getMassages() {
    return _firestore.collection('massages').orderBy('order').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => Massage.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<Massage>> getMassagesOnce() async {
    final snapshot = await _firestore
        .collection('massages')
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => Massage.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> createMassage(Massage massage) async {
    // Get total count of massages to set order
    final allMassages = await _firestore.collection('massages').get();
    final order =
        allMassages.docs.length; // New massage gets order = total count

    final data = massage.toMap();
    // Override createdAt with server timestamp and set order
    data['createdAt'] = FieldValue.serverTimestamp();
    data['order'] = order;
    await _firestore.collection('massages').doc(massage.id).set(data);
  }

  Future<void> updateMassageOrder(List<String> massageIds) async {
    // Update order for all massages based on their new positions
    final batch = _firestore.batch();
    for (int i = 0; i < massageIds.length; i++) {
      final docRef = _firestore.collection('massages').doc(massageIds[i]);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  Future<void> updateMassage(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('massages').doc(id).update(updates);
  }

  Future<void> deleteMassage(String id) async {
    // Get all massages ordered by order before deletion
    final allMassages = await _firestore
        .collection('massages')
        .orderBy('order')
        .get();

    // Create batch for atomic operation (delete + reorder)
    final batch = _firestore.batch();

    // Delete the massage
    final docToDelete = allMassages.docs.firstWhere((doc) => doc.id == id);
    batch.delete(docToDelete.reference);

    // Reorder remaining massages to fill the gap (sequential 0, 1, 2, 3...)
    final remainingMassages = allMassages.docs
        .where((doc) => doc.id != id)
        .toList();
    for (int i = 0; i < remainingMassages.length; i++) {
      batch.update(remainingMassages[i].reference, {'order': i});
    }

    // Commit all operations atomically
    await batch.commit();
  }

  // Treatments (same structure as massages, different collection)
  Stream<List<Massage>> getTreatments() {
    return _firestore.collection('treatments').orderBy('order').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => Massage.fromMap(doc.data(), doc.id))
            .toList();
      },
    );
  }

  Future<List<Massage>> getTreatmentsOnce() async {
    final snapshot = await _firestore
        .collection('treatments')
        .orderBy('order')
        .get();

    return snapshot.docs
        .map((doc) => Massage.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> createTreatment(Massage treatment) async {
    // Get total count of treatments to set order
    final allTreatments = await _firestore.collection('treatments').get();
    final order =
        allTreatments.docs.length; // New treatment gets order = total count

    final data = treatment.toMap();
    // Override createdAt with server timestamp and set order
    data['createdAt'] = FieldValue.serverTimestamp();
    data['order'] = order;
    await _firestore.collection('treatments').doc(treatment.id).set(data);
  }

  Future<void> updateTreatmentOrder(List<String> treatmentIds) async {
    // Update order for all treatments based on their new positions
    final batch = _firestore.batch();
    for (int i = 0; i < treatmentIds.length; i++) {
      final docRef = _firestore.collection('treatments').doc(treatmentIds[i]);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  Future<void> updateTreatment(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('treatments').doc(id).update(updates);
  }

  Future<void> deleteTreatment(String id) async {
    // Get all treatments ordered by order before deletion
    final allTreatments = await _firestore
        .collection('treatments')
        .orderBy('order')
        .get();

    // Create batch for atomic operation (delete + reorder)
    final batch = _firestore.batch();

    // Delete the treatment
    final docToDelete = allTreatments.docs.firstWhere((doc) => doc.id == id);
    batch.delete(docToDelete.reference);

    // Reorder remaining treatments to fill the gap (sequential 0, 1, 2, 3...)
    final remainingTreatments = allTreatments.docs
        .where((doc) => doc.id != id)
        .toList();
    for (int i = 0; i < remainingTreatments.length; i++) {
      batch.update(remainingTreatments[i].reference, {'order': i});
    }

    // Commit all operations atomically
    await batch.commit();
  }

  // Closed Days
  Stream<List<ClosedDay>> getClosedDays() {
    return _firestore
        .collection('closedDays')
        .orderBy('date', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClosedDay.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<ClosedDay>> getClosedDaysOnce() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('closedDays')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ClosedDay.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<String> createClosedDay(ClosedDay closedDay) async {
    final docRef = await _firestore
        .collection('closedDays')
        .add(closedDay.toMap());
    return docRef.id;
  }

  Future<void> deleteClosedDay(String id) async {
    await _firestore.collection('closedDays').doc(id).delete();
  }

  // Firebase Storage - Image Upload
  Future<String> uploadServiceImage(
    File imageFile,
    String serviceId,
    bool isTreatment,
  ) async {
    try {
      final collection = isTreatment ? 'treatments' : 'massages';
      final storagePath =
          '$collection/$serviceId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child(storagePath);
      await ref.putFile(imageFile);

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  // Firebase Storage - Image Upload (for web using bytes)
  Future<String> uploadServiceImageBytes(
    Uint8List imageBytes,
    String serviceId,
    bool isTreatment,
  ) async {
    try {
      final collection = isTreatment ? 'treatments' : 'massages';
      final storagePath =
          '$collection/$serviceId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = _storage.ref().child(storagePath);
      await ref.putData(imageBytes);

      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  Future<void> deleteServiceImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Log error but don't throw - image might already be deleted
      debugPrint('Erreur lors de la suppression de l\'image: $e');
    }
  }

  // Contact Messages
  Future<void> createContactMessage({
    required String name,
    required String message,
    String? contactMethod,
    String? email,
    String? phone,
  }) async {
    final data = {
      'name': name,
      'message': message,
      'contactMethod': contactMethod,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'read': false,
    };

    if (email != null && email.isNotEmpty) {
      data['email'] = email;
    }

    if (phone != null && phone.isNotEmpty) {
      data['phone'] = phone;
    }

    await _firestore.collection('contactMessages').add(data);
  }

  // Get contact messages
  Stream<List<Map<String, dynamic>>> getContactMessages() {
    return _firestore
        .collection('contactMessages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Mark contact message as read
  Future<void> markContactMessageAsRead(String messageId) async {
    await _firestore.collection('contactMessages').doc(messageId).update({
      'read': true,
    });
  }

  // Answer a contact message
  Future<void> answerContactMessage(String messageId, String answer) async {
    await _firestore.collection('contactMessages').doc(messageId).update({
      'answer': answer,
      'answered': true,
      'read': true,
      'answeredAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Mark a contact message as answered (for phone calls, no answer text needed)
  Future<void> markContactMessageAsAnswered(String messageId) async {
    await _firestore.collection('contactMessages').doc(messageId).update({
      'answered': true,
      'read': true,
      'answeredAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
