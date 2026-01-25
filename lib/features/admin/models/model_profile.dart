import 'package:cloud_firestore/cloud_firestore.dart';

class ModelProfile {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? profilePhotoUrl;
  final String? city;
  final String? country;
  final String? height;
  final String? bust;
  final String? waist;
  final String? hips;
  final String? shoeSize;
  final String? eyeColor;
  final String? hairColor;
  final String? skinTone;
  final String? experience;
  final List<String>? categories;
  final List<String>? portfolioUrls;
  final String? portfolioVideoUrl;
  final bool? willingToTravel;
  final bool? idVerified;
  final bool? portfolioApproved;
  final DateTime? portfolioReviewDate;
  final bool? stripeOnboardingComplete;
  final bool? stripeChargesEnabled;
  final bool? stripePayoutsEnabled;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ModelProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.bio,
    this.profilePhotoUrl,
    this.city,
    this.country,
    this.height,
    this.bust,
    this.waist,
    this.hips,
    this.shoeSize,
    this.eyeColor,
    this.hairColor,
    this.skinTone,
    this.experience,
    this.categories,
    this.portfolioUrls,
    this.portfolioVideoUrl,
    this.willingToTravel,
    this.idVerified,
    this.portfolioApproved,
    this.portfolioReviewDate,
    this.stripeOnboardingComplete,
    this.stripeChargesEnabled,
    this.stripePayoutsEnabled,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModelProfile.fromFirestore(Map<String, dynamic> data, String id) {
    Timestamp? createdAtTimestamp;
    if (data['created_at'] is Timestamp) {
      createdAtTimestamp = data['created_at'] as Timestamp;
    } else if (data['created_at'] != null) {
      createdAtTimestamp = data['created_at'];
    }

    Timestamp? updatedAtTimestamp;
    if (data['updated_at'] is Timestamp) {
      updatedAtTimestamp = data['updated_at'] as Timestamp;
    } else if (data['updated_at'] != null) {
      updatedAtTimestamp = data['updated_at'];
    }

    Timestamp? portfolioReviewTimestamp;
    if (data['portfolio_review_date'] is Timestamp) {
      portfolioReviewTimestamp = data['portfolio_review_date'] as Timestamp;
    } else if (data['portfolio_review_date'] != null) {
      portfolioReviewTimestamp = data['portfolio_review_date'];
    }

    return ModelProfile(
      id: id,
      userId: data['user_id'] ?? '',
      firstName: data['first_name'],
      lastName: data['last_name'],
      bio: data['bio'],
      profilePhotoUrl: data['profile_photo_url'],
      city: data['city'],
      country: data['country'],
      height: data['height'],
      bust: data['bust'],
      waist: data['waist'],
      hips: data['hips'],
      shoeSize: data['shoe_size'],
      eyeColor: data['eye_color'],
      hairColor: data['hair_color'],
      skinTone: data['skin_tone'],
      experience: data['experience'],
      categories: data['categories'] != null ? List<String>.from(data['categories']) : null,
      portfolioUrls: data['portfolio_urls'] != null ? List<String>.from(data['portfolio_urls']) : null,
      portfolioVideoUrl: data['portfolio_video_url'],
      willingToTravel: data['willing_to_travel'],
      idVerified: data['id_verified'],
      portfolioApproved: data['portfolio_approved'],
      portfolioReviewDate: portfolioReviewTimestamp?.toDate(),
      stripeOnboardingComplete: data['stripe_onboarding_complete'],
      stripeChargesEnabled: data['stripe_charges_enabled'],
      stripePayoutsEnabled: data['stripe_payouts_enabled'],
      adminNotes: data['admin_notes'],
      createdAt: createdAtTimestamp?.toDate() ?? DateTime.now(),
      updatedAt: updatedAtTimestamp?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'bio': bio,
      'profile_photo_url': profilePhotoUrl,
      'city': city,
      'country': country,
      'height': height,
      'bust': bust,
      'waist': waist,
      'hips': hips,
      'shoe_size': shoeSize,
      'eye_color': eyeColor,
      'hair_color': hairColor,
      'skin_tone': skinTone,
      'experience': experience,
      'categories': categories,
      'portfolio_urls': portfolioUrls,
      'portfolio_video_url': portfolioVideoUrl,
      'willing_to_travel': willingToTravel,
      'id_verified': idVerified,
      'portfolio_approved': portfolioApproved,
      'portfolio_review_date': portfolioReviewDate != null ? Timestamp.fromDate(portfolioReviewDate!) : null,
      'stripe_onboarding_complete': stripeOnboardingComplete,
      'stripe_charges_enabled': stripeChargesEnabled,
      'stripe_payouts_enabled': stripePayoutsEnabled,
      'admin_notes': adminNotes,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}
