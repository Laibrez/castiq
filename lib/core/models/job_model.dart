import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String brandId;
  final String brandName;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final double rate;
  final List<String> requirements;
  final String status; // 'open', 'closed', 'completed'
  final DateTime createdAt;
  final List<String> images;
  final Map<String, String> documents;


  JobModel({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.rate,
    required this.requirements,
    this.status = 'open',
    required this.createdAt,
    this.images = const [],
    this.documents = const {},
  });

  factory JobModel.fromMap(Map<String, dynamic> data, String id) {
    return JobModel(
      id: id,
      brandId: data['brandId'] ?? '',
      brandName: data['brandName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rate: (data['rate'] as num?)?.toDouble() ?? 0.0,
      requirements: data['requirements'] != null ? List<String>.from(data['requirements']) : [],
      status: data['status'] ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      documents: data['documents'] != null ? Map<String, String>.from(data['documents']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brandId': brandId,
      'brandName': brandName,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'rate': rate,
      'requirements': requirements,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'images': images,
      'documents': documents,
    };
  }
}
