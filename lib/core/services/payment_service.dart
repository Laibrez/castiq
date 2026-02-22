import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initPaymentSheet(String bookingId) async {
    try {
      // 1. Create payment intent on the server
      final result = await FirebaseFunctions.instance.httpsCallable('createPaymentIntent').call({
        'bookingId': bookingId,
      });

      final data = result.data;

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['paymentIntent'],
          merchantDisplayName: 'Caztiq',
          customerId: data['customer'],
          // customerEphemeralKeySecret: data['ephemeralKey'],
          style: ThemeMode.dark,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> presentPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      rethrow;
    }
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

  Stream<List<PaymentModel>> getUserPayments(String userId) {
    return _firestore
        .collection('payments')
        .where(Filter.or(
          Filter('brandId', isEqualTo: userId),
          Filter('modelId', isEqualTo: userId),
        ))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
