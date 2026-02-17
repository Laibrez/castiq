import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch jobs with filters
  Future<List<JobModel>> getJobs({
    String? category,
    double? minPay,
    double? maxPay,
    DateTime? startDate,
    DateTime? endDate,
    int? maxExperienceRequired, // "experienceRequired" <= modelExperience (max because job requires <=)
    int? modelHeight, // For height compatibility
    bool? isUrgent,
    bool? isInstantPayoutAvailable,
    String? contractType,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _firestore.collection('jobs').where('status', isEqualTo: 'open');

    // 1. Category
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    // 2. Pay Range
    if (minPay != null) {
      query = query.where('payRate', isGreaterThanOrEqualTo: minPay);
    }
    if (maxPay != null) {
      query = query.where('payRate', isLessThanOrEqualTo: maxPay);
    }

    // 3. Shoot Date Range
    if (startDate != null) {
      query = query.where('shootDate', isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where('shootDate', isLessThanOrEqualTo: endDate);
    }

    // 5. Experience Required
    if (maxExperienceRequired != null) {
      query = query.where('experienceRequired', isLessThanOrEqualTo: maxExperienceRequired);
    }

    // 6. Height Compatibility
    if (modelHeight != null) {
      query = query.where('heightMin', isLessThanOrEqualTo: modelHeight);
      query = query.where('heightMax', isGreaterThanOrEqualTo: modelHeight);
    }

    // 9. Contract Type
    if (contractType != null && contractType.isNotEmpty) {
      query = query.where('contractType', isEqualTo: contractType);
    }

    // 10. Urgent Jobs Only
    if (isUrgent == true) {
      query = query.where('isUrgent', isEqualTo: true);
    }

    // Instant Payout
    if (isInstantPayoutAvailable == true) {
      query = query.where('isInstantPayoutAvailable', isEqualTo: true);
    }

    // Order by createdAt desc (or relevant field)
    // Note: ordering requires indexes matching the inequality filters.
    // If filtering by payRate, must order by payRate first.
    // This gets complex. For now, let's keep it simple and add basic ordering if no range filter prevents it.
    
    // query = query.orderBy('createdAt', descending: true); // This will likely fail with range filters on other fields

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) => JobModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
  }

  Future<void> applyToJob(String jobId, String modelId, String brandId) async {
    final application = Application(
      id: '', // Auto-generated
      jobId: jobId,
      modelId: modelId,
      brandId: brandId,
      status: 'pending',
      appliedAt: DateTime.now(),
    );

    await _firestore.collection('applications').add(application.toMap());
  }
}
