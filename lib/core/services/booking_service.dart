import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking request
  Future<void> createBooking(BookingModel booking) async {
    try {
      await _firestore.collection('bookings').add(booking.toMap());
    } catch (e) {
      throw e;
    }
  }

  // Fetch bookings for a user (Model or Brand)
  Stream<List<BookingModel>> getUserBookings(String userId, String role) {
    String field = role == 'model' ? 'modelId' : 'brandId';
    return _firestore
        .collection('bookings')
        .where(field, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in memory to avoid requiring a composite index
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({'status': status});
    } catch (e) {
      throw e;
    }
  }

  // Update check-in/out
  Future<void> updateCheckInOut(String bookingId, {DateTime? checkIn, DateTime? checkOut, String? selfieUrl}) async {
    try {
      Map<String, dynamic> data = {};
      if (checkIn != null) data['checkInTime'] = Timestamp.fromDate(checkIn);
      if (checkOut != null) data['checkOutTime'] = Timestamp.fromDate(checkOut);
      if (selfieUrl != null) data['selfieUrl'] = selfieUrl;
      
      await _firestore.collection('bookings').doc(bookingId).update(data);
    } catch (e) {
      throw e;
    }
  }
}
