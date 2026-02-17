import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String brandId;
  final String brandName;
  final String title;
  final String category; // 'Runway', 'Editorial', 'Swimsuit', 'Commercial', 'Fitness', 'Luxury Campaign'
  final String description;
  final String location;
  final DateTime shootDate;
  final double payRate;
  // "Jobs Completed" is another filter.
  // "Years of Experience" is a brand filter.
  // For Job Filter 5: "Experience Required where(experienceRequired <= modelExperience)".
  // This implies experienceRequired is a minimum level. Let's use int for years.
  final int experienceRequired; 
  final int heightMin;
  final int heightMax;
  final String genderRequirement;
  final String contractType; // 'One-day', 'Multi-day', 'Long-term'
  final String status; // "open" | "closed"
  final bool isUrgent;
  final bool isInstantPayoutAvailable;
  final DateTime createdAt;
  final List<String> images;
  final Map<String, String> documents;

  JobModel({
    required this.id,
    required this.brandId,
    required this.brandName,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.shootDate,
    required this.payRate,
    required this.experienceRequired,
    required this.heightMin,
    required this.heightMax,
    required this.genderRequirement,
    required this.contractType,
    this.status = 'open',
    this.isUrgent = false,
    this.isInstantPayoutAvailable = false,
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
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      shootDate: (data['shootDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      payRate: (data['payRate'] as num?)?.toDouble() ?? 0.0,
      experienceRequired: (data['experienceRequired'] as num?)?.toInt() ?? 0,
      heightMin: (data['heightMin'] as num?)?.toInt() ?? 0,
      heightMax: (data['heightMax'] as num?)?.toInt() ?? 0,
      genderRequirement: data['genderRequirement'] ?? '',
      contractType: data['contractType'] ?? 'One-day',
      status: data['status'] ?? 'open',
      isUrgent: data['isUrgent'] ?? false,
      isInstantPayoutAvailable: data['isInstantPayoutAvailable'] ?? false,
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
      'category': category,
      'description': description,
      'location': location,
      'shootDate': Timestamp.fromDate(shootDate),
      'payRate': payRate,
      'experienceRequired': experienceRequired,
      'heightMin': heightMin,
      'heightMax': heightMax,
      'genderRequirement': genderRequirement,
      'contractType': contractType,
      'status': status,
      'isUrgent': isUrgent,
      'isInstantPayoutAvailable': isInstantPayoutAvailable,
      'createdAt': FieldValue.serverTimestamp(),
      'images': images,
      'documents': documents,
    };
  }
}
