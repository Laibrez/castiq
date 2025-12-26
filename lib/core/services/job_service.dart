import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/core/models/job_model.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new job
  Future<void> createJob(JobModel job) async {
    try {
      await _firestore.collection('jobs').add(job.toMap());
    } catch (e) {
      throw e;
    }
  }

  // Fetch all open jobs
  Stream<List<JobModel>> getOpenJobs() {
    return _firestore
        .collection('jobs')
        .where('status', isEqualTo: 'open')
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList();
          // Sort in memory to avoid index requirement
          jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return jobs;
        });
  }

  // Fetch jobs posted by a specific brand
  Stream<List<JobModel>> getBrandJobs(String brandId) {
    return _firestore
        .collection('jobs')
        .where('brandId', isEqualTo: brandId)
        .snapshots()
        .map((snapshot) {
          final jobs = snapshot.docs
            .map((doc) => JobModel.fromMap(doc.data(), doc.id))
            .toList();
          // Sort in memory
          jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return jobs;
        });
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({'status': status});
    } catch (e) {
      throw e;
    }
  }
}
