import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  final String id;
  final String jobId;
  final String modelId;
  final String brandId;
  final String status; // "pending", "accepted", "rejected"
  final DateTime appliedAt;

  Application({
    required this.id,
    required this.jobId,
    required this.modelId,
    required this.brandId,
    required this.status,
    required this.appliedAt,
  });

  factory Application.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Application(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      modelId: data['modelId'] ?? '',
      brandId: data['brandId'] ?? '',
      status: data['status'] ?? 'pending',
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'modelId': modelId,
      'brandId': brandId,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
    };
  }
}
