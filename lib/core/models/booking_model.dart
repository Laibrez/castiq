import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String jobId;
  final String brandId;
  final String modelId;
  final String status; // 'pending', 'confirmed', 'signed', 'in_progress', 'completed', 'paid'
  final String? contractUrl;
  final String? modelSignature;
  final String? brandSignature;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? selfieUrl;
  final String? paymentMethod; // 'visa', 'mastercard', 'paypal'
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.jobId,
    required this.brandId,
    required this.modelId,
    required this.status,
    this.contractUrl,
    this.modelSignature,
    this.brandSignature,
    this.checkInTime,
    this.checkOutTime,
    this.selfieUrl,
    required this.createdAt,
    this.paymentMethod,
  });

  factory BookingModel.fromMap(Map<String, dynamic> data, String id) {
    return BookingModel(
      id: id,
      jobId: data['jobId'] ?? '',
      brandId: data['brandId'] ?? '',
      modelId: data['modelId'] ?? '',
      status: data['status'] ?? 'pending',
      contractUrl: data['contractUrl'],
      modelSignature: data['modelSignature'],
      brandSignature: data['brandSignature'],
      checkInTime: (data['checkInTime'] as Timestamp?)?.toDate(),
      checkOutTime: (data['checkOutTime'] as Timestamp?)?.toDate(),
      selfieUrl: data['selfieUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: data['paymentMethod'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'brandId': brandId,
      'modelId': modelId,
      'status': status,
      'contractUrl': contractUrl,
      'modelSignature': modelSignature,
      'brandSignature': brandSignature,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'selfieUrl': selfieUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
    };
  }
}
