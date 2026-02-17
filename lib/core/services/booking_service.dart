import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_application_1/core/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new booking request via Cloud Functions
  Future<void> createBooking(BookingModel booking) async {
    try {
      await FirebaseFunctions.instance.httpsCallable('createBooking').call({
        'modelId': booking.modelId,
        'jobId': booking.jobId,
        'rate': booking.rate,
        'details': {
          'date': booking.date?.toIso8601String(),
          'location': booking.location,
          'hours': booking.hours,
          'description': booking.description,
          'cancellationTerms': booking.cancellationTerms,
          'jobTitle': booking.jobTitle,
        }
      });
    } catch (e) {
      rethrow;
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

  // Fetch bookings for a specific job
  Stream<List<BookingModel>> getJobBookings(String jobId) {
    return _firestore
        .collection('bookings')
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();
      });
  }


  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      if (status == 'offer_accepted') {
        await FirebaseFunctions.instance.httpsCallable('acceptOffer').call({
          'bookingId': bookingId,
        });
      } else {
        // Fallback for other statuses not yet migrated or purely client-side for now
        await _firestore.collection('bookings').doc(bookingId).update({'status': status});
      }
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }

  // Digital signature
  Future<void> signContract(String bookingId, String role, String signature) async {
    try {
      final data = {
        role == 'brand' ? 'brandSignature' : 'modelSignature': signature,
        role == 'brand' ? 'brandSignedAt' : 'modelSignedAt': FieldValue.serverTimestamp(),
      };
      await _firestore.collection('bookings').doc(bookingId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Confirm job completion (Brand)
  Future<void> confirmCompletion(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'completed',
        'brandConfirmedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Dispute job (Brand)
  Future<void> disputeJob(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'isDisputed': true,
      });
    } catch (e) {
      rethrow;
    }
  }
}
