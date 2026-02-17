import 'package:cloud_firestore/cloud_firestore.dart';

class Contract {
  final String id;
  final String jobId;
  final String brandId;
  final String modelId;
  final double payRate;
  final String deliverables;
  final DateTime shootDate;
  final bool brandSigned;
  final bool modelSigned;
  final String status; // "awaiting_model_signature", "active", "completed", "cancelled"
  final String stripeDepositStatus; // "pending", "funded", "released"
  final DateTime? checkInTime;
  final bool modelMarkedComplete;
  final bool brandMarkedComplete;
  final String? qrToken;

  Contract({
    required this.id,
    required this.jobId,
    required this.brandId,
    required this.modelId,
    required this.payRate,
    required this.deliverables,
    required this.shootDate,
    required this.brandSigned,
    required this.modelSigned,
    required this.status,
    required this.stripeDepositStatus,
    this.checkInTime,
    this.modelMarkedComplete = false,
    this.brandMarkedComplete = false,
    this.qrToken,
  });

  factory Contract.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Contract(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      brandId: data['brandId'] ?? '',
      modelId: data['modelId'] ?? '',
      payRate: (data['payRate'] ?? 0).toDouble(),
      deliverables: data['deliverables'] ?? '',
      shootDate: (data['shootDate'] as Timestamp).toDate(),
      brandSigned: data['brandSigned'] ?? false,
      modelSigned: data['modelSigned'] ?? false,
      status: data['status'] ?? 'awaiting_model_signature',
      stripeDepositStatus: data['stripeDepositStatus'] ?? 'pending',
      checkInTime: data['checkInTime'] != null ? (data['checkInTime'] as Timestamp).toDate() : null,
      modelMarkedComplete: data['modelMarkedComplete'] ?? false,
      brandMarkedComplete: data['brandMarkedComplete'] ?? false,
      qrToken: data['qrToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'brandId': brandId,
      'modelId': modelId,
      'payRate': payRate,
      'deliverables': deliverables,
      'shootDate': Timestamp.fromDate(shootDate),
      'brandSigned': brandSigned,
      'modelSigned': modelSigned,
      'status': status,
      'stripeDepositStatus': stripeDepositStatus,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'modelMarkedComplete': modelMarkedComplete,
      'brandMarkedComplete': brandMarkedComplete,
      'qrToken': qrToken,
    };
  }
}
