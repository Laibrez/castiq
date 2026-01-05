import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String brandId;
  final String modelId;
  final String bookingId;
  final String jobTitle;
  final double amount;
  final String method; // 'paypal', 'card', 'credit', 'debit'
  final String status; // 'pending', 'completed', 'failed'
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.brandId,
    required this.modelId,
    required this.bookingId,
    required this.jobTitle,
    required this.amount,
    required this.method,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'brandId': brandId,
      'modelId': modelId,
      'bookingId': bookingId,
      'jobTitle': jobTitle,
      'amount': amount,
      'method': method,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentModel(
      id: id,
      brandId: map['brandId'] ?? '',
      modelId: map['modelId'] ?? '',
      bookingId: map['bookingId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      method: map['method'] ?? '',
      status: map['status'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
