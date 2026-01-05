import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createPayment(PaymentModel payment) async {
    await _firestore.collection('payments').add(payment.toMap());
    
    // Update booking status to 'paid'
    await _firestore.collection('bookings').doc(payment.bookingId).update({
      'status': 'paid',
    });
  }

  Stream<List<PaymentModel>> getBrandPayments(String brandId) {
    return _firestore
        .collection('payments')
        .where('brandId', isEqualTo: brandId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<PaymentModel>> getModelPayments(String modelId) {
    return _firestore
        .collection('payments')
        .where('modelId', isEqualTo: modelId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
