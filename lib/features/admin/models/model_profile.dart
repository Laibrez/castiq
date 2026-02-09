import 'package:cloud_firestore/cloud_firestore.dart';

class ModelProfile {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? profilePhotoUrl;
  final String? city;
  final String? country;
  final List<String> categories;
  final bool idVerified;
  final bool portfolioApproved;
  final bool stripeOnboardingComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ModelProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.profilePhotoUrl,
    this.city,
    this.country,
    this.categories = const [],
    this.idVerified = false,
    this.portfolioApproved = false,
    this.stripeOnboardingComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ModelProfile.fromFirestore(Map<String, dynamic> data, String docId) {
    return ModelProfile(
      id: docId,
      userId: data['user_id'] ?? '',
      firstName: data['first_name'],
      lastName: data['last_name'],
      profilePhotoUrl: data['profile_photo_url'],
      city: data['city'],
      country: data['country'],
      categories: List<String>.from(data['categories'] ?? []),
      idVerified: data['id_verified'] ?? false,
      portfolioApproved: data['portfolio_approved'] ?? false,
      stripeOnboardingComplete: data['stripe_onboarding_complete'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate(),
    );
  }
}
