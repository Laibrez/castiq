import 'package:cloud_firestore/cloud_firestore.dart';

class Invitation {
  final String id;
  final String brandId;
  final String modelId;
  final String jobId;
  final String status; // "sent", "accepted", "declined"
  final DateTime sentAt;

  Invitation({
    required this.id,
    required this.brandId,
    required this.modelId,
    required this.jobId,
    required this.status,
    required this.sentAt,
  });

  factory Invitation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Invitation(
      id: doc.id,
      brandId: data['brandId'] ?? '',
      modelId: data['modelId'] ?? '',
      jobId: data['jobId'] ?? '',
      status: data['status'] ?? 'sent',
      sentAt: (data['sentAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brandId': brandId,
      'modelId': modelId,
      'jobId': jobId,
      'status': status,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
