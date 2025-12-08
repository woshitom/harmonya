import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../models/customer.dart';
import '../models/gift_voucher.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final docRef = await _firestore.collection('gift_vouchers').add(voucher.toMap());
    return docRef.id;
  }

  Future<void> updateGiftVoucher(String id, Map<String, dynamic> updates) async {
    await _firestore.collection('gift_vouchers').doc(id).update(updates);
  }

  Stream<List<GiftVoucher>> getGiftVouchers() {
    return _firestore
        .collection('gift_vouchers')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => GiftVoucher.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
