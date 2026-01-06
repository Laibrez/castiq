import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String jobId;
  final String brandId;
  final String modelId;
  final String status; // 'pending', 'confirmed', 'signed', 'in_progress', 'awaiting_confirmation', 'completed', 'paid'
  final String? contractUrl;
  final String? modelSignature;
  final String? brandSignature;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? selfieUrl;
  final String? paymentMethod; // 'visa', 'mastercard', 'paypal'
  final String? jobTitle;
  final double? rate;
  final String? location;
  final DateTime? date;
  final double? hours;
  final String? description;
  final String? cancellationTerms;
  final DateTime? brandSignedAt;
  final DateTime? modelSignedAt;
  final DateTime? brandConfirmedAt;
  final bool isDisputed;
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
    this.paymentMethod,
    this.jobTitle,
    this.rate,
    this.location,
    this.date,
    this.hours,
    this.description,
    this.cancellationTerms,
    this.brandSignedAt,
    this.modelSignedAt,
    this.brandConfirmedAt,
    this.isDisputed = false,
    required this.createdAt,
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
      jobTitle: data['jobTitle'],
      rate: (data['rate'] ?? 0.0).toDouble(),
      location: data['location'],
      date: (data['date'] as Timestamp?)?.toDate(),
      hours: (data['hours'] ?? 0.0).toDouble(),
      description: data['description'],
      cancellationTerms: data['cancellationTerms'],
      brandSignedAt: (data['brandSignedAt'] as Timestamp?)?.toDate(),
      modelSignedAt: (data['modelSignedAt'] as Timestamp?)?.toDate(),
      brandConfirmedAt: (data['brandConfirmedAt'] as Timestamp?)?.toDate(),
      isDisputed: data['isDisputed'] ?? false,
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
      'jobTitle': jobTitle,
      'rate': rate,
      'location': location,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'hours': hours,
      'description': description,
      'cancellationTerms': cancellationTerms,
      'brandSignedAt': brandSignedAt != null ? Timestamp.fromDate(brandSignedAt!) : null,
      'modelSignedAt': modelSignedAt != null ? Timestamp.fromDate(modelSignedAt!) : null,
      'brandConfirmedAt': brandConfirmedAt != null ? Timestamp.fromDate(brandConfirmedAt!) : null,
      'isDisputed': isDisputed,
    };
  }
}
